<?php
/**
 * Lightweight healthcheck for Kubernetes probes.
 * Checks PHP-FPM, MySQL (mysqli), and Redis in <100ms.
 * Returns JSON: {"status":"ok","php":true,"db":true,"redis":true,"ms":12}
 * HTTP 200 = all healthy, HTTP 503 = at least one component down.
 */
header("Content-Type: application/json");
$start = hrtime(true);
$checks = ["php" => true, "db" => false, "redis" => false];
$errors = [];

// --- MySQL check (mysqli, SELECT 1) ---
try {
  $host =
    getenv("MW_DB_HOST") ?:
    "mysql-pxc-db-haproxy.pxc-clusters.svc.cluster.local";
  $user = getenv("MW_DB_USER") ?: "mediawiki";
  $pass = getenv("MW_DB_PASSWORD") ?: "";
  $db = getenv("MW_DB_NAME") ?: "mediawiki";
  mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
  $conn = new mysqli($host, $user, $pass, $db);
  $conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 3);
  $result = $conn->query("SELECT 1");
  if ($result) {
    $checks["db"] = true;
    $result->free();
  }
  $conn->close();
} catch (Throwable $e) {
  $errors[] = "db: " . $e->getMessage();
}

// --- Redis check (PING) ---
try {
  $redis = new Redis();
  $redis->connect(
    getenv("MW_REDIS_HOST") ?: "redis.mediawiki.svc.cluster.local",
    6379,
    2,
  );
  if ($redis->ping()) {
    $checks["redis"] = true;
  } else {
    $errors[] = "redis: ping failed";
  }
  $redis->close();
} catch (Throwable $e) {
  $errors[] = "redis: " . $e->getMessage();
}

$ms = (int) ((hrtime(true) - $start) / 1e6);
$healthy = $checks["db"] && $checks["redis"];
http_response_code($healthy ? 200 : 503);

echo json_encode(
  [
    "status" => $healthy ? "ok" : "degraded",
    "php" => $checks["php"],
    "db" => $checks["db"],
    "redis" => $checks["redis"],
    "ms" => $ms,
  ] + ($errors ? ["errors" => $errors] : []),
  JSON_UNESCAPED_SLASHES,
);
