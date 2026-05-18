# hosts/kenobi/parts/storage.nix — Local storage directories for k3s workloads.
#
# Creates host-local directories that k3s pods can mount via hostPath.
# These persist across pod restarts AND node reboots (unlike emptyDir).
#
# Why hostPath instead of a CSI PV?
#   kenobi has no ZFS pool (unlike chopper). It's a compute-only OCI VM.
#   For workloads that need persistence but not the overhead of a full CSI
#   driver, a pre-created directory with correct ownership is simplest.
{ ... }:
{
  # Create the PXC RAM replica data directory.
  # Owned by mysql user/group (UID/GID 1001) — matches what the PXC container
  # expects. The PXC operator's init container runs as root but writes here,
  # and the main container (UID 1001) needs full access.
  systemd.tmpfiles.rules = [
    "d /var/lib/pxc-ram 0777 root root -"
  ];
}
