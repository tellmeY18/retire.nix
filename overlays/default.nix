# overlays/default.nix — all custom package overlays
#
# Imported by flake.nix as:
#   overlays = import ./overlays { inherit inputs; };
#
# Individual overlays are applied to hosts via nixpkgs.overlays.
# External overlays (e.g. fenix) are NOT managed here — they stay
# in the host's extraModules list.
{ inputs }: {
  # Custom packages overlay — adds our own derivations to nixpkgs
  custom-packages = final: _prev: {

    # Prebuilt release .app instead of the source build (which compiles 15 npm
    # plugins locally and flakes on a libuv/kqueue assertion on macOS).
    super-productivity = final.callPackage ../packages/super-productivity-bin.nix { };

    # Pull entire from nixpkgs-entire (pinned to a master commit with 0.9.0)
    # instead of nixpkgs-unstable (which still ships 0.8.42).
    entire = inputs.nixpkgs-entire.legacyPackages.${final.stdenv.hostPlatform.system}.entire;
  };
}
