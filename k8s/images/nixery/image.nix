# Build the nixery container image from upstream sources.
#
# This evaluates tazjin/nixery's default.nix and extracts the
# nixery-image attribute, which produces a Docker-loadable tarball
# via dockerTools.buildLayeredImage.
#
# Usage:
#   nix-build image.nix --option sandbox false
#   docker load < result
#   docker tag nixery:latest ghcr.io/tellmey18/nixery:latest
#
# The nixery-src/ directory must contain a checkout of tazjin/nixery.
# CI checks it out automatically; for local builds:
#   git clone --depth 1 https://github.com/tazjin/nixery.git nixery-src
let
  pkgs = import <nixpkgs> { };
in
(import ./nixery-src/default.nix { inherit pkgs; }).nixery-image
