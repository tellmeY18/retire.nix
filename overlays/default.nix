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
  custom-packages = final: prev: {
    gomuks = final.callPackage ../packages/gomuks/default.nix { };

    # Pull signal-cli from nixpkgs-signal (pinned to a master commit with 0.14.5)
    # instead of nixpkgs-unstable (which still ships 0.14.3 as of July 2026).
    # 0.14.5 fixes NPE on inbound messages caused by the server omitting
    # serverGuid from sealed-sender envelopes.
    signal-cli = inputs.nixpkgs-signal.legacyPackages.${final.system}.signal-cli;
  };
}
