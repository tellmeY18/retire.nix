# hosts/kenobi/parts/storage.nix — Local storage directories for k3s workloads.
#
# Creates host-local directories that k3s pods can mount via hostPath.
# These persist across pod restarts AND node reboots (unlike emptyDir).
#
# Used by the two MySQL workloads that live on kenobi:
#   - mysql-mediawiki  — MediaWiki's standalone Percona Server (sole backend).
#   - mysql-ghost (-c) — the quorum-only Group Replication member.
{ ... }:
{
  # Directories are 0777 so the percona container (UID 1001) can write;
  # hostPath volumes ignore the pod's fsGroup.
  systemd.tmpfiles.rules = [
    # MediaWiki's standalone MySQL data directory (renamed from pxc-ram).
    "d /var/lib/mysql-mediawiki 0777 root root -"
    # Ghost MySQL — quorum-only Group Replication member. Persistent across
    # reboots (so it rejoins without a full re-clone), but the durable copies
    # live on the ZFS-backed members on chopper/c3po.
    "d /var/lib/mysql-ghost 0777 root root -"
  ];
}
