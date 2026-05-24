# Binary cache configuration — shared across all hosts.
#
# Adds the self-hosted Attic cache (on the tailnet) as a substituter
# so packages built by CI are pulled as pre-built binaries, never
# compiled locally.
#
# The Attic cache is public-read (no token needed to pull), but pushes
# require authentication (handled by CI via ATTIC_TOKEN secret).
#
# Architecture:
#   CI (GitHub Actions) → builds all configs → pushes to Attic
#   Hosts (on tailnet)  → pull from Attic as a substituter
#
# Prerequisites:
#   - The host must be on the tailnet (Attic is tailnet-only)
#   - The Attic server must be running: attic.tail477f2f.ts.net:8080
#   - The 'system' cache must exist and be public
{ ... }:
{
  nix.settings = {
    # Substituters are tried in order. Official cache first (likely has
    # most packages), then our Attic for custom builds + flake-update outputs.
    substituters = [
      "https://cache.nixos.org"
      "http://attic.tail477f2f.ts.net:8080/system"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # Attic cache signing key (auto-generated at cache creation)
      "system:mvnfTi6w7gvX6oksJ4JhHLL4wVUa576bgtLJ6lh9C2Y="
    ];

    # Trust the Attic HTTP endpoint (not HTTPS, encrypted via WireGuard/tailnet)
    trusted-substituters = [
      "http://attic.tail477f2f.ts.net:8080/system"
    ];
  };
}
