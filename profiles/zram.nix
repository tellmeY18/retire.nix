# profiles/zram.nix — ZRAM swap for memory pressure relief.
#
# ZRAM creates a compressed RAM-based block device used as swap space.
# Benefits:
#   - Faster than disk swap (compression/decompression in RAM)
#   - Reduces SSD write wear (critical for laptop nodes chopper/c3po)
#   - Prevents OOM kills during load spikes without disk I/O latency
#
# Per-host tuning:
#   - Laptops / storage nodes (chopper, c3po): zstd for better compression
#   - Low-CPU nodes (kenobi ARM): lz4 for speed; lower memoryPercent
#
# Coexists with ZFS zvol swap (c3po): ZRAM gets priority 100, zvol has
# priority -1 (default), so the kernel fills ZRAM first and only falls
# through to the slow zvol when ZRAM is fully consumed.
#
# Also includes a systemd timer that exports ZRAM metrics via the
# node_exporter textfile collector, since the upstream node_exporter
# Docker image does not ship the built-in ZRAM collector compiled in.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) types mkOption mdDoc;

  # Script that collects ZRAM metrics from sysfs and writes Prometheus
  # exposition format for node_exporter's textfile collector.
  zramCollector = pkgs.writeShellScript "node-exporter-zram" ''
    OUTPUT=/var/lib/node-exporter/textfile/zram.prom
    TMP="''${OUTPUT}.tmp.$$"

    # Write to temp file, then atomically rename
    {
      for device in /sys/block/zram*; do
        [ -e "$device" ] || continue
        dev=$(basename "$device")

        disksize=$(cat "$device/disksize" 2>/dev/null) || disksize=0
        compr_data_size=$(cat "$device/compr_data_size" 2>/dev/null) || compr_data_size=0
        orig_data_size=$(cat "$device/orig_data_size" 2>/dev/null) || orig_data_size=0
        mem_used_total=$(cat "$device/mem_used_total" 2>/dev/null) || mem_used_total=0
        num_reads=$(cat "$device/num_reads" 2>/dev/null) || num_reads=0
        num_writes=$(cat "$device/num_writes" 2>/dev/null) || num_writes=0
        zero_pages=$(cat "$device/zero_pages" 2>/dev/null) || zero_pages=0
        failed_reads=$(cat "$device/failed_reads" 2>/dev/null) || failed_reads=0
        failed_writes=$(cat "$device/failed_writes" 2>/dev/null) || failed_writes=0

        # Print metrics as Prometheus exposition format
        echo '# HELP node_zram_disksize ZRAM device disk size in bytes.'
        echo '# TYPE node_zram_disksize gauge'
        echo "node_zram_disksize{device=\"$dev\"} $disksize"
        echo '# HELP node_zram_compr_data_size ZRAM compressed data size in bytes.'
        echo '# TYPE node_zram_compr_data_size gauge'
        echo "node_zram_compr_data_size{device=\"$dev\"} $compr_data_size"
        echo '# HELP node_zram_orig_data_size ZRAM original (uncompressed) data size in bytes.'
        echo '# TYPE node_zram_orig_data_size gauge'
        echo "node_zram_orig_data_size{device=\"$dev\"} $orig_data_size"
        echo '# HELP node_zram_mem_used_total ZRAM memory used including metadata in bytes.'
        echo '# TYPE node_zram_mem_used_total gauge'
        echo "node_zram_mem_used_total{device=\"$dev\"} $mem_used_total"
        echo '# HELP node_zram_num_reads_total ZRAM number of read requests.'
        echo '# TYPE node_zram_num_reads_total counter'
        echo "node_zram_num_reads_total{device=\"$dev\"} $num_reads"
        echo '# HELP node_zram_num_writes_total ZRAM number of write requests.'
        echo '# TYPE node_zram_num_writes_total counter'
        echo "node_zram_num_writes_total{device=\"$dev\"} $num_writes"
        echo '# HELP node_zram_zero_pages ZRAM number of zero-filled pages.'
        echo '# TYPE node_zram_zero_pages gauge'
        echo "node_zram_zero_pages{device=\"$dev\"} $zero_pages"
        echo '# HELP node_zram_failed_reads_total ZRAM number of failed reads.'
        echo '# TYPE node_zram_failed_reads_total counter'
        echo "node_zram_failed_reads_total{device=\"$dev\"} $failed_reads"
        echo '# HELP node_zram_failed_writes_total ZRAM number of failed writes.'
        echo '# TYPE node_zram_failed_writes_total counter'
        echo "node_zram_failed_writes_total{device=\"$dev\"} $failed_writes"
      done
    } > "$TMP" 2>/dev/null && mv -f "$TMP" "$OUTPUT" || rm -f "$TMP"
  '';
in
{
  options.profiles.zram = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Enable ZRAM swap with sensible defaults per host role.";
    };

    memoryPercent = mkOption {
      type = types.int;
      default = 50;
      description = mdDoc ''
        Percentage of total RAM to allocate for ZRAM.
        Lower values (30) for low-CPU hosts, higher (50) for general use.
      '';
    };

    algorithm = mkOption {
      type = types.str;
      default = "zstd";
      description = mdDoc ''
        Compression algorithm. zstd for best ratio (default),
        lz4 for speed on low-CPU hosts.
      '';
    };
  };

  config = lib.mkIf config.profiles.zram.enable {
    zramSwap = {
      enable = true;
      memoryPercent = config.profiles.zram.memoryPercent;
      algorithm = config.profiles.zram.algorithm;
    };

    # ----------------------------------------------------------------------
    # ZRAM metrics for node_exporter textfile collector
    #
    # The official node_exporter Docker image does not ship the ZRAM collector
    # compiled in, so we use the textfile collector pattern (same approach as
    # the community's node-exporter-textfile-collector-scripts repo).
    #
    # This systemd timer reads /sys/block/zram* sysfs files every 60s and
    # writes Prometheus exposition format to the textfile directory that
    # node_exporter mounts from the host.
    #
    # Metrics exposed:
    #   node_zram_disksize           — total ZRAM device size (bytes)
    #   node_zram_compr_data_size    — compressed data stored (bytes)
    #   node_zram_orig_data_size     — original uncompressed data (bytes)
    #   node_zram_mem_used_total     — memory used incl. metadata (bytes)
    #   node_zram_num_reads_total    — read I/O count
    #   node_zram_num_writes_total   — write I/O count
    #   node_zram_zero_pages         — zero-filled pages (stored empty)
    #   node_zram_failed_reads_total — failed read count
    #   node_zram_failed_writes_total— failed write count
    # ----------------------------------------------------------------------

    # Ensure the textfile directory exists
    systemd.tmpfiles.rules = [
      "d /var/lib/node-exporter/textfile 0755 root root -"
    ];

    # Service: runs the ZRAM collector script
    systemd.services.node-exporter-zram = {
      description = "ZRAM metrics for node_exporter textfile collector";
      after = [ "dev-zram0.device" ];
      bindsTo = [ "dev-zram0.device" ];
      unitConfig.ConditionPathExists = "/sys/block/zram0";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = zramCollector;
      };
    };

    # Timer: collect every 60s (matches node_exporter scrape interval)
    systemd.timers.node-exporter-zram = {
      description = "ZRAM metrics collection timer for node_exporter textfile";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "1m";
      };
    };
  };
}
