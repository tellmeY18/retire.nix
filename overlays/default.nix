# overlays/default.nix — all custom package overlays
#
# Imported by flake.nix as:
#   overlays = import ./overlays;
#
# Individual overlays are applied to hosts via nixpkgs.overlays.
# External overlays (e.g. fenix) are NOT managed here — they stay
# in the host's extraModules list.
{
  # Custom packages overlay — adds our own derivations to nixpkgs
  custom-packages = final: prev: {
    neondb = final.callPackage ../packages/neondb/default.nix { };
  };
}
