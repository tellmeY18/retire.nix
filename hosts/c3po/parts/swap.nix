# hosts/c3po/parts/swap.nix — ZFS zvol swap for memory pressure relief.
#
# c3po runs the full k3s control plane (etcd + apiserver) plus workloads
# on only 7.6 GB RAM. Without swap, load spikes cause the API server to
# starve, kubelet can't heartbeat → node goes NotReady → connections drop.
#
# The zvol provides a stable swap device on the existing ZFS pool.
# swappiness=10 means we only swap under real pressure (not proactively).
{ ... }:
{
  # ZFS zvol swap — created manually as `zfs create -V 4G rpool/swap`
  # (disko doesn't manage this; the zvol persists across rebuilds)
  swapDevices = [
    { device = "/dev/zvol/rpool/swap"; }
  ];

  # Only swap under real memory pressure — keep hot pages in RAM
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    # Reduce inode/dentry cache pressure (helps ZFS ARC coexist with k3s)
    "vm.vfs_cache_pressure" = 50;
  };
}
