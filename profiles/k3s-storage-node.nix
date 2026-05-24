# profiles/k3s-storage-node.nix — Profile for on-prem laptop/storage k3s nodes.
#
# These nodes are the DATA LAYER of the cluster:
#   - Run ZFS pools with OpenEBS ZFS LocalPV
#   - Host ALL PVCs (databases, TSDB, etc.)
#   - Always available (laptops plugged in, on mains power)
#   - PRECIOUS: limited RAM/CPU — reserved for data-engine pods
#   - LUXURIOUS: abundant fast NVMe storage
#
# Scheduling model:
#   - Labeled with `node-role.glug.infra/storage=true`
#   - Tainted with `node-role.glug.infra/storage-only=true:PreferNoSchedule`
#     This SOFT taint tells the scheduler: "avoid putting stateless pods here
#     unless compute nodes are unavailable". When compute nodes ARE available,
#     stateless pods land there. When compute nodes go down, the scheduler
#     overflows back to storage nodes (the taint is soft — not a hard refusal).
#   - Pods that need PVCs tolerate this taint automatically because they MUST
#     run here (topology constraint forces it).
#   - DaemonSets (node-exporter, OpenEBS) tolerate all taints by default.
#
# The net effect:
#   - Compute nodes UP:   storage nodes run only DB pods + DaemonSets (lean)
#   - Compute nodes DOWN: storage nodes accept all workloads (graceful fallback)
#
# What this profile adds on top of k3s-node.nix:
#   - Node labels: `node-role.glug.infra/storage=true`
#   - Node taint: `PreferNoSchedule` for non-storage workloads
#   - ZFS tools and OpenEBS prerequisites
#
# Usage in a host configuration:
#
#   imports = [ ../../profiles/k3s-storage-node.nix ];
#
#   services.k3s-cluster = {
#     enable    = true;
#     role      = "server-init";
#     # ...
#   };
{
  config,
  ...
}:

{
  imports = [ ./k3s-node.nix ];

  # ---------------------------------------------------------------------------
  # Node labels + taint — applied at k3s startup via flags.
  #
  # Labels:
  #   node-role.glug.infra/storage=true — StorageClass topology constraint key
  #   topology.kubernetes.io/zone=on-prem — pod topology spread
  #
  # Taint:
  #   node-role.glug.infra/storage-only=true:PreferNoSchedule
  #     SOFT taint: scheduler avoids placing stateless pods here when compute
  #     nodes have capacity. Does NOT hard-reject — if all compute nodes are
  #     down, stateless pods still land here as a fallback.
  #     Pods with PVCs ignore this because they're forced here by topology.
  #     DaemonSets ignore all PreferNoSchedule taints by default.
  # ---------------------------------------------------------------------------
  services.k3s-cluster.extraFlags = [
    "--node-label=node-role.glug.infra/storage=true"
    "--node-label=topology.kubernetes.io/zone=on-prem"
    "--node-taint=node-role.glug.infra/storage-only=true:PreferNoSchedule"
  ];

  # ---------------------------------------------------------------------------
  # Assertions — fail the build if critical prerequisites are missing.
  # ---------------------------------------------------------------------------
  assertions = [
    {
      assertion = config.boot.supportedFilesystems.zfs or false;
      message = ''
        profiles/k3s-storage-node.nix requires ZFS support.
        Import profiles/zfs.nix or set boot.supportedFilesystems.zfs = true.
      '';
    }
  ];
}
