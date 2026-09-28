# hosts/yoda/parts/users.nix — user accounts.
#
# The OCI Ubuntu image blocks root SSH (forced "login as ubuntu" command), so
# nixos-anywhere connects as the `ubuntu` sudo user. Once NixOS is installed,
# root SSH with the keys below works directly (deploy-rs + admin access).
#
# Identical across the VM hosts, so it lives in one place.
import ../../../profiles/admin-user.nix
