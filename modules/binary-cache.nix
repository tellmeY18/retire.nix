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
#
# Graceful fallback strategy:
#   If attic (either endpoint) is unavailable, Nix will silently skip it
#   and try the next substituter (cache.nixos.org). If all substituters
#   fail, Nix will build from source (no blocking).
#
#   Substituter order (priority):
#     1. cache.nixos.org      — always available, most reliable
#     2. attic tailnet        — fast when available, may fail DNS
#     3. attic public ingress — fallback if tailnet unreachable
#
#   DNS resolution timeout (curl): ~30s default. If attic is
#   unreachable, expect up to 30s delay before falling back to
#   cache.nixos.org. Consider setting CURLOPT_CONNECTTIMEOUT=10
#   for faster failure if this becomes a blocker.
{ ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      # Direct tailnet endpoint (fast, lowest latency). Only resolvable on
      # nodes with Tailscale MagicDNS (accept-dns=true), i.e. c3po.
      "http://attic.tail477f2f.ts.net:8080/system"
      # Public Traefik ingress (resolvable via public DNS everywhere). Nodes
      # with accept-dns=false (chopper, kenobi) can't resolve the tailnet name
      # above and fall through to this. Same store, same signing key.
      "https://cache.tellmey.fyi/system"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "system:mvnfTi6w7gvX6oksJ4JhHLL4wVUa576bgtLJ6lh9C2Y="
    ];

    # Both attic endpoints serve the same store (signed by the key above).
    trusted-substituters = [
      "http://attic.tail477f2f.ts.net:8080/system"
      "https://cache.tellmey.fyi/system"
    ];
  };
}
