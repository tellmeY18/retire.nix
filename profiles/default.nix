# profiles/default.nix — role-to-profile mapping
#
# This attrset maps role names (as declared in hosts/*/metadata.nix)
# to their corresponding profile modules. Used by lib/default.nix
# to auto-resolve roles into imports.
#
# Usage (manual, until lib wiring is done):
#   let profiles = import ../../profiles;
#   in { imports = [ profiles.base profiles.laptop ]; }
{
  base = ./base.nix;
  laptop = ./laptop.nix;
  server = ./server.nix;
  zfs = ./zfs.nix;
  wayland = ./wayland.nix;
  dev = ./dev.nix;
  k3s = ./k3s-node.nix;
}
