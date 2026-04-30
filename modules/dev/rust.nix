# modules/dev/rust.nix — Shared Rust toolchain configuration via Fenix.
#
# Import this from any host that needs Rust development tools.
# The fenix overlay (fenix.overlays.default) must already be applied to
# nixpkgs for the `pkgs.fenix.*` attributes to exist.
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    pkgs.rust-analyzer-nightly
  ];
}
