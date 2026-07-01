# hosts/yoda/default.nix — parts composition (phase 1: bootstrap).
#
# Deliberately minimal and secret-free:
#   - boot     : UEFI + systemd-boot + ZFS + OCI virtio/serial console
#   - network  : DHCP on ens3 (MTU 9000), firewall (SSH only)
#   - users    : vysakh + root SSH keys, openssh
#
# NOT included yet (phase 2): ./sops.nix, ./parts/k3s.nix, Tailscale.
{ ... }:
{
  system.stateVersion = "25.11";

  imports = [
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/users.nix
  ];
}
