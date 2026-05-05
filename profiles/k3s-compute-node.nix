# profiles/k3s-compute-node.nix — Profile for ephemeral cloud VM compute nodes.
#
# These nodes are the COMPUTE LAYER of the cluster:
#   - Pure CPU/RAM resources — no local persistent storage
#   - May disappear at any time (spot instances, preemptible VMs, restarts)
#   - NEVER host PVCs — all persistent state lives on storage nodes
#   - LUXURIOUS: abundant CPU/RAM for stateless workloads
#   - Run stateless workloads: operators, proxies, web apps, workers, CI
#
# Scheduling model:
#   - Labeled with `node-role.glug.infra/compute=true`
#   - Labeled with `topology.kubernetes.io/zone=cloud`
#   - NO taints — eagerly accepts all stateless workloads
#   - Combined with the storage node's `PreferNoSchedule` taint, stateless
#     pods will PREFER these nodes over storage nodes. The scheduler sees:
#       "compute node: no taints, welcome!"
#       "storage node: PreferNoSchedule, avoid if possible"
#   - NO ZFS, NO OpenEBS — PVCs physically cannot be created here
#
# Failure mode:
#   When compute nodes go down (spot eviction, maintenance, outage):
#   - Pods rescheduled to storage nodes (soft taint allows it)
#   - Storage nodes run at minimum viable capacity until compute returns
#   - Databases are unaffected (they were already on storage nodes)
#
# What this profile does NOT include:
#   - No ZFS packages, no ZFS kernel modules
#   - No OpenEBS / StorageClass provisioner
#   - No textfile collector for ZFS metrics (there's no ZFS)
#   - No battery monitoring (it's a VM, not a laptop)
#
# Usage in a host configuration:
#
#   imports = [ ../../profiles/k3s-compute-node.nix ];
#
#   services.k3s-cluster = {
#     enable     = true;
#     role       = "agent";       # typically just a worker
#     serverAddr = "https://chopper:6443";
#     tokenFile  = config.sops.secrets.k3s-token.path;
#     nodeIP     = "100.x.y.z";  # tailscale IP of this VM
#   };
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./k3s-node.nix ];

  # ---------------------------------------------------------------------------
  # Node labels — applied at k3s startup.
  #
  # Labels:
  #   node-role.glug.infra/compute=true    — identifies compute-only nodes
  #   topology.kubernetes.io/zone=cloud    — used by pod topology spread
  #
  # NO taint — these nodes eagerly accept all stateless workloads.
  # The scheduling preference is driven by the STORAGE node's taint
  # (PreferNoSchedule), which pushes stateless pods AWAY from storage
  # and toward these untainted compute nodes.
  # ---------------------------------------------------------------------------
  services.k3s-cluster.extraFlags = [
    "--node-label=node-role.glug.infra/compute=true"
    "--node-label=topology.kubernetes.io/zone=cloud"
  ];

  # ---------------------------------------------------------------------------
  # Explicitly do NOT load ZFS — these nodes have no persistent storage.
  # If ZFS kernel module is absent, OpenEBS DaemonSet pods will be in
  # CrashLoopBackOff on this node (expected, handled by nodeSelector in
  # the OpenEBS chart). The CSI node plugin tolerates this gracefully.
  # ---------------------------------------------------------------------------
  # boot.supportedFilesystems.zfs = lib.mkForce false;  # uncomment if base profile enables ZFS

  # ---------------------------------------------------------------------------
  # Minimal system packages — no storage tools, just cluster admin essentials.
  # (Already provided by k3s-node.nix: kubectl, helm, helmfile, k9s, sops, just)
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Ephemeral storage for pod scratch space.
  # Cloud VMs typically have ephemeral NVMe/SSD. Mount it as /var/lib/kubelet
  # so that emptyDir volumes, container layers, and logs use fast local disk
  # without needing PVCs. This is NOT persistent across VM replacement.
  # ---------------------------------------------------------------------------
  # Uncomment and adjust for your cloud provider's ephemeral disk device:
  # fileSystems."/var/lib/kubelet" = {
  #   device = "/dev/nvme1n1";
  #   fsType = "ext4";
  #   options = [ "defaults" "noatime" "discard" ];
  # };
}
