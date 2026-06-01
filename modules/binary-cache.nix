# Binary cache configuration — shared across all hosts.
#
# Adds the self-hosted Attic cache as a substituter so packages built
# by CI are pulled as pre-built binaries, never compiled locally.
#
# All hosts are on the Tailscale network, so they use the direct tailnet
# URL (WireGuard-encrypted, no relay overhead, full bandwidth).
#
# CI (GitHub Actions) uses the Funnel URL instead (public HTTPS) since
# runners are NOT on the tailnet. See .github/workflows/flake-update.yml.
#
# Architecture:
#   CI → pushes via https://attic-push.tail477f2f.ts.net (Funnel, public)
#   Hosts → pull via http://attic.tail477f2f.ts.net:8080 (tailnet, direct)
{ ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "http://attic.tail477f2f.ts.net:8080/system"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "system:mvnfTi6w7gvX6oksJ4JhHLL4wVUa576bgtLJ6lh9C2Y="
    ];

    # Trust the HTTP endpoint (not HTTPS — already encrypted via WireGuard)
    trusted-substituters = [
      "http://attic.tail477f2f.ts.net:8080/system"
    ];
  };
}
