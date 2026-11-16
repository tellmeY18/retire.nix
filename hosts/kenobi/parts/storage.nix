# hosts/kenobi/parts/storage.nix — Local storage directories for k3s workloads.
#
# Creates host-local directories that k3s pods can mount via hostPath.
# These persist across pod restarts AND node reboots (unlike emptyDir).
#
# Used by mysql-mediawiki — MediaWiki's standalone Percona Server (sole backend).
{ ... }:
{
  # Directory is 0777 so the percona container (UID 1001) can write;
  # hostPath volumes ignore the pod's fsGroup.
  systemd.tmpfiles.rules = [
    # MediaWiki's standalone MySQL data directory (renamed from pxc-ram).
    "d /var/lib/mysql-mediawiki 0777 root root -"
  ];
}
