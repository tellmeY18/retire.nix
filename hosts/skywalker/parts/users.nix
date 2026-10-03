# hosts/skywalker/parts/users.nix — user accounts.
#
# Keys come from users/vysakh.nix, same as every other host. Root keeps SSH
# keys for nixos-anywhere (install) and deploy-rs (updates).
#
# Identical across the VM hosts, so it lives in one place.
{ pkgs, ... }:
{
  imports = [ ../../../profiles/admin-user.nix ];

  # Temporary guest account for Serene — office GNOME desktop use only.
  # No SSH keys, no wheel/networkmanager. Remove when no longer needed.
  users.users.serene = {
    isNormalUser = true;
    description = "Serene (guest)";
    shell = pkgs.bash;
    initialPassword = "changeme";
  };
}
