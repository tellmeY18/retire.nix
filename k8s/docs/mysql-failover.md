# MySQL Failover: PXC → RAM Replica Auto-Promotion

> **Status:** TODO — blocked on password policy unification (see Prerequisites)

## Goal

If the primary PXC cluster (chopper) goes offline, the RAM replica (kenobi)
should automatically become the sole MySQL backend for all traffic (reads AND
writes). When PXC returns, the RAM replica demotes itself back to read-only.

## Current Architecture

```
MediaWiki / Ghost
       │
   ProxySQL
       ├── hostgroup 10 (WRITER) → mysql-pxc-db-haproxy.pxc-clusters.svc (chopper)
       └── hostgroup 20 (READER) → mysql-ram-pxc.pxc-ram.svc (kenobi)
```

- RAM replica: `read-only=ON`, `super-read-only=ON`, async replication from PXC
- ProxySQL monitor: **DISABLED** (`mysql-monitor_enabled=false`)
- Failover: **none** — if PXC dies, writes fail silently (timeout → 503)

## Target Architecture

```
MediaWiki / Ghost
       │
   ProxySQL (monitor ENABLED)
       ├── hostgroup 10 (WRITER) → PXC HAProxy  ← primary
       ├── hostgroup 10 (WRITER) → RAM replica   ← backup (only when PXC is DOWN)
       └── hostgroup 20 (READER) → RAM replica   ← always
       │
   failover-sidecar (watches ProxySQL stats)
       └── promotes/demotes RAM replica based on PXC health
```

## Prerequisites (blockers)

- [ ] **Unify password policies** — the RAM replica has different user passwords
  than PXC. ProxySQL monitor needs consistent credentials to health-check both
  backends. Fix: sync the `monitor` user + app user passwords across both MySQL
  instances.
- [ ] **Re-enable ProxySQL monitor** — currently disabled because monitor user
  credentials don't match. After password unification, set
  `mysql-monitor_enabled=true` in the ProxySQL config.
- [ ] **Test replication consistency** — verify GTID positions are in sync and
  the RAM replica can cleanly accept writes after `STOP REPLICA`.

## Implementation Plan

### Step 1: Password Unification

Create a consistent set of MySQL users across PXC and RAM:

```sql
-- On PXC primary (via HAProxy):
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED BY '<unified-password>';
GRANT REPLICATION CLIENT ON *.* TO 'monitor'@'%';

-- On RAM replica (after STOP REPLICA for writes):
-- Already replicated via async replication, but verify.
```

Update ProxySQL config:
```
mysql-monitor_username="monitor"
mysql-monitor_password="<unified-password>"
mysql-monitor_enabled=true
```

### Step 2: ProxySQL Replication Hostgroups

Replace static hostgroup routing with replication-aware routing:

```sql
-- ProxySQL admin:
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup, check_type)
VALUES (10, 20, 'read_only');
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

This tells ProxySQL: check each server's `read_only` variable. Servers with
`read_only=OFF` → hostgroup 10 (writer). Servers with `read_only=ON` →
hostgroup 20 (reader).

### Step 3: Failover Sidecar

A lightweight container in the ProxySQL pod that:

1. Every 10s: queries ProxySQL admin for hostgroup 10 server status
2. If hostgroup 10 has 0 ONLINE servers for >30s (confirmed outage):
   - Connects to RAM replica
   - `STOP REPLICA; SET GLOBAL read_only=OFF; SET GLOBAL super_read_only=OFF;`
   - ProxySQL monitor detects `read_only=OFF` → moves RAM to hostgroup 10
   - Log: "FAILOVER: RAM replica promoted to writer"
3. If PXC comes back (hostgroup 10 original server becomes reachable):
   - Waits 60s for stability
   - Connects to RAM replica
   - `SET GLOBAL read_only=ON; SET GLOBAL super_read_only=ON; START REPLICA;`
   - ProxySQL monitor detects `read_only=ON` → moves RAM back to hostgroup 20
   - Log: "RECOVERY: RAM replica demoted, PXC resumed as writer"

### Step 4: Split-Brain Prevention

- The failover sidecar holds a lease (ConfigMap lock or simple file flag)
- Only ONE promotion can happen at a time
- Before promoting RAM: verify PXC is truly unreachable (not just slow)
  - Ping PXC 3 times with 5s intervals
  - Check ProxySQL `ConnFree` + `ConnUsed` counters (0 = truly dead)
- Before demoting RAM: verify PXC has caught up (GTID comparison)
  - If RAM accepted writes while PXC was down, PXC must replicate those
    back before resuming as primary (or accept data divergence)

## Risks & Caveats

| Risk | Mitigation |
|------|-----------|
| Split-brain (both accept writes) | Failover sidecar holds exclusive lease; 30s grace period |
| Data loss on failover (async replication lag) | Accept: async replication has inherent RPO > 0. Log GTID position at promotion time for manual reconciliation if needed. |
| RAM replica runs out of memory under write load | RAM node has 4Gi limit with 2Gi buffer pool — sufficient for MediaWiki/Ghost write patterns. Monitor with alerts. |
| PXC comes back with stale data | After recovery, PXC must re-sync from RAM (reverse replication) or accept divergence. Document the manual reconciliation procedure. |
| ProxySQL monitor false positive | Use `connect_timeout_server_ms=3000` and `monitor_ping_interval=2000` — require 3 consecutive failures before marking DOWN. |

## Monitoring & Alerts

Add to VictoriaMetrics rules:

- `ProxySQLWriterDown` (critical): hostgroup 10 has 0 ONLINE servers for >30s
- `MySQLRAMPromoted` (warning): RAM replica has `read_only=OFF` (failover active)
- `ReplicationLagHigh` (warning): `Seconds_Behind_Source > 10` on RAM replica
- `FailoverSidecarUnhealthy` (critical): sidecar container not running

## Files to Create/Modify

| File | Change |
|------|--------|
| `proxysql/proxysql-config-secret.enc.yaml` | Enable monitor, add replication hostgroups, add RAM as backup in HG10 |
| `proxysql/deployment.yaml` | Add failover-sidecar container |
| `pxc-ram/mysql-ram-config.yaml` | Document that `read-only` will be toggled by the sidecar |
| `monitoring/proxysql-failover-vmrules.yaml` | Alerting rules |
| Users/passwords | Unify across PXC + RAM + ProxySQL |

## Manual Failover (emergency, before automation is ready)

If PXC dies and you need to promote RAM manually RIGHT NOW:

```sh
# 1. Stop replication and enable writes on RAM
kubectl exec -n pxc-ram mysql-ram-0 -c mysql -- mysql -uroot -e "
  STOP REPLICA;
  SET GLOBAL read_only=OFF;
  SET GLOBAL super_read_only=OFF;
"

# 2. Point ProxySQL hostgroup 10 to RAM
kubectl exec -n proxysql deployment/proxysql -- mysql -h127.0.0.1 -P6032 -uradmin -p'admin' -e "
  UPDATE mysql_servers SET status='SHUNNED' WHERE hostgroup_id=10 AND hostname LIKE '%pxc%';
  INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10, 'mysql-ram-pxc.pxc-ram.svc.cluster.local', 3306);
  LOAD MYSQL SERVERS TO RUNTIME;
"

# 3. Verify
kubectl exec -n proxysql deployment/proxysql -- mysql -h127.0.0.1 -P6032 -uradmin -p'admin' -e "
  SELECT hostgroup, srv_host, status FROM stats_mysql_connection_pool WHERE hostgroup=10;
"
```

To demote after PXC returns:
```sh
# 1. Remove RAM from writer hostgroup
kubectl exec -n proxysql deployment/proxysql -- mysql -h127.0.0.1 -P6032 -uradmin -p'admin' -e "
  DELETE FROM mysql_servers WHERE hostgroup_id=10 AND hostname LIKE '%ram%';
  UPDATE mysql_servers SET status='ONLINE' WHERE hostgroup_id=10 AND hostname LIKE '%pxc%';
  LOAD MYSQL SERVERS TO RUNTIME;
"

# 2. Re-enable read-only and restart replication on RAM
kubectl exec -n pxc-ram mysql-ram-0 -c mysql -- mysql -uroot -e "
  SET GLOBAL read_only=ON;
  SET GLOBAL super_read_only=ON;
  START REPLICA;
"
```
