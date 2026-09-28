# hosts/skywalker/parts/users.nix — user accounts.
#
# Keys come from users/vysakh.nix, same as every other host. Root keeps SSH
# keys for nixos-anywhere (install) and deploy-rs (updates).
#
# Identical across the VM hosts, so it lives in one place.
import ../../../profiles/admin-user.nix
