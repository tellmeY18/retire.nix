{ pkgs, ... }:

{
  # Ensure ZFS and vfat are available in the initrd for root-on-ZFS boot
  boot.initrd.availableKernelModules = [ "zfs" ];
  boot.supportedFilesystems = [
    "zfs"
    "vfat"
  ];

  # Use the latest ZFS package if needed (optional, uncomment if you want unstable)
  # boot.zfs.package = pkgs.zfs_unstable;

  # ---------------------------------------------------------------------------
  # ZFS ARC memory limits
  # ---------------------------------------------------------------------------
  # The ZFS Adaptive Replacement Cache (ARC) defaults to claiming up to 50%
  # of total RAM. On a 7.6GB laptop running k3s + CNPG + Prometheus + Grafana,
  # that's ~3.8GB for ARC alone — leaving the system perpetually swapping or
  # OOM-killing pods.
  #
  # Cap ARC at 1.5GB max (1,610,612,736 bytes) to leave ~6GB for pods and
  # kernel. ARC min at 256MB (268,435,456 bytes) ensures ZFS always has
  # enough cache for metadata-heavy operations (scrubs, imports).
  #
  # These are ZFS kernel module parameters, set via boot.kernelParams so
  # they apply before the pool is imported.
  #
  # Monitor ARC effectiveness after this change:
  #   just k8s::zfs-arc-hit-ratio    (should stay > 80% for normal workloads)
  #   just k8s::zfs-arc-size          (verify it stays within bounds)
  #   cat /proc/spl/kstat/zfs/arcstats | grep ^size
  #
  # zswap — compressed swap cache in RAM
  # ---------------------------------------------------------------------------
  # zswap intercepts pages being swapped out, compresses them with zstd, and
  # stores them in a RAM pool. Only pages that don't compress well (or when
  # the pool is full) actually hit the NVMe swap partition. This effectively
  # gives 2-3x more "usable" memory before hitting disk swap latency.
  #
  # Pool size: 20% of RAM ≈ 1.5GB. With ~2:1 average compression, this holds
  # ~3GB of logical swap data in RAM.
  #
  # zstd gives the best compression ratio. For the zpool allocator:
  #   - z3fold was removed in Linux 6.14
  #   - zsmalloc is the modern replacement (built-in on 6.14+)
  boot.kernelParams = [
    # ZFS ARC limits
    "zfs.zfs_arc_max=1610612736" # 1.5 GiB
    "zfs.zfs_arc_min=268435456" # 256 MiB
    # zswap
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=20"
    "zswap.zpool=zsmalloc"
  ];

  # ---------------------------------------------------------------------------
  # VM / swap tuning — optimised for ZFS on a memory-constrained laptop
  # ---------------------------------------------------------------------------
  boot.kernel.sysctl = {
    # --- Swap aggressiveness ---
    # Default: 60. On Linux 5.8+, values up to 200 are valid.
    # Higher values tell the kernel to prefer swapping anonymous (inactive
    # application) pages over dropping file cache. This is critical on ZFS
    # because:
    #   1. ZFS ARC is kernel memory, invisible to the VM page scanner.
    #   2. The kernel sees very little "file cache" to reclaim (ARC ate it).
    #   3. Without swapping, the only option is OOM-killing pods.
    # 150 aggressively pushes idle pod memory to swap, keeping RAM free for
    # active workloads and ARC.
    "vm.swappiness" = 150;

    # --- VFS cache pressure ---
    # Default: 100. Lower = kernel hangs on to dentry/inode caches longer.
    # ZFS doesn't use the kernel page cache for data (ARC handles that), but
    # it DOES use VFS dentries and inodes for path lookups. Keeping these
    # cached improves `ls`, `stat`, and path resolution on ZFS datasets.
    # 50 = half as aggressive as default at reclaiming VFS metadata.
    "vm.vfs_cache_pressure" = 50;

    # --- Watermark tuning ---
    # watermark_scale_factor controls when kswapd wakes up to start reclaiming.
    # Default: 10 (0.1% of RAM ≈ 7.6MB). At 125 (1.25% ≈ 95MB), kswapd
    # starts reclaiming earlier, avoiding sudden memory cliffs where the
    # allocator stalls waiting for free pages.
    "vm.watermark_scale_factor" = 125;

    # Disable watermark boost — it can cause unnecessary reclaim bursts on
    # systems with fragmented memory (common with ZFS + k3s).
    "vm.watermark_boost_factor" = 0;

    # --- Dirty page writeback ---
    # On ZFS, these mainly affect non-ZFS filesystems (tmpfs, procfs, etc.)
    # and the writeback of swapped pages. Tighter limits prevent dirty pages
    # from accumulating and causing latency spikes.
    "vm.dirty_ratio" = 10; # % of RAM before sync writes stall
    "vm.dirty_background_ratio" = 5; # % of RAM before background writeback

    # --- Minimum free memory ---
    # Reserve 128MB for kernel-critical allocations. Prevents the last-resort
    # OOM killer from firing during normal memory pressure spikes (pod startup,
    # ZFS scrub, etc.). Default is ~67MB on 7.6GB.
    "vm.min_free_kbytes" = 131072; # 128 MiB
  };

  # Enable ZFS auto-scrub and trim for maintenance
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # Optional: Enable ZFS event daemon for automatic snapshots, etc.
  # services.zfs.zed.enable = true;

  # Optional: Add ZFS tools to systemPackages for convenience
  environment.systemPackages = with pkgs; [
    zfs
    zfstools
  ];
}
