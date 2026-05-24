# profiles/zfs-openebs-datasets.nix — Declaratively ensure OpenEBS ZFS datasets exist.
#
# This profile creates the ZFS datasets that OpenEBS ZFS LocalPV needs.
# Import this on any node that should host PVCs.
#
# Usage:
#   imports = [ ../../profiles/zfs-openebs-datasets.nix ];
#
# Datasets created:
#   rpool/openebs      — recordsize=8K  (PostgreSQL/CNPG)
#   rpool/openebs-16k  — recordsize=16K (MySQL/PXC)
#   rpool/k3s          — recordsize=16K (k3s server data)
#
{ config, ... }:
let
  pool = "rpool";
in
{
  # Create datasets on every boot if they don't exist.
  # ZFS create is idempotent — it no-ops if the dataset already exists.
  systemd.services.ensure-openebs-datasets = {
    description = "Ensure OpenEBS ZFS datasets exist";
    after = [ "zfs-import.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "k3s.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ config.boot.zfs.package ];
    script = ''
      # 8K recordsize — optimal for PostgreSQL (8KB pages)
      zfs create -o recordsize=8k -o compression=zstd -o logbias=throughput \
        -o atime=off -o xattr=sa ${pool}/openebs 2>/dev/null || true

      # 16K recordsize — optimal for MySQL/InnoDB (16KB pages)
      zfs create -o recordsize=16k -o compression=zstd -o logbias=throughput \
        -o atime=off -o xattr=sa ${pool}/openebs-16k 2>/dev/null || true

      # k3s server data (etcd, manifests)
      zfs create -o recordsize=16k -o atime=off ${pool}/k3s 2>/dev/null || true

      echo "OpenEBS datasets ready:"
      zfs list -o name,recordsize,compression,used,avail -r ${pool}/openebs ${pool}/openebs-16k ${pool}/k3s
    '';
  };
}
