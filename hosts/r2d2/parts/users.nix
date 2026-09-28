# hosts/r2d2/parts/users.nix
# User accounts — note: vladmin keys for cloud-init, vysakh for nix management.
# Once nixos-anywhere provisions the new system, cloud-init user is replaced
# by NixOS-declared users.
#
# Identical across the VM hosts, so it lives in one place.
import ../../../profiles/admin-user.nix
