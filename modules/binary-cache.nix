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
#   CI → pushes via https://cache.tellmey.fyi (public Traefik ingress)
#   NixOS nodes → pull via http://attic.tail477f2f.ts.net:8080 (tailnet, fast)
#   darwin (mac) → pull via https://cache.tellmey.fyi (public; accept-dns=false
#                  means the nix daemon can't resolve .tail477f2f.ts.net)
#
# Fallback behaviour:
#   fallback = true  — if a substituter errors (DNS failure, 5xx, timeout),
#                      nix tries the next one and ultimately builds from source.
#   connect-timeout = 5  — fail fast on unreachable substituters instead of
#                          blocking for the default 30 s.
#
#   Substituter order (priority):
#     1. cache.nixos.org      — always available, most reliable
#     2. attic tailnet        — fast on NixOS nodes; DNS error on darwin
#                               (falls through via fallback=true)
#     3. attic public ingress — resolvable everywhere via public DNS
{ ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      # Direct tailnet endpoint (fast, lowest latency). Resolvable on NixOS
      # nodes that resolve MagicDNS via their own nameserver config.
      # On darwin the nix daemon reads /etc/resolv.conf (192.168.1.1) and
      # can't resolve this; fallback=true lets it skip to the public endpoint.
      "http://attic.tail477f2f.ts.net:8080/system"
      # Public Traefik ingress — resolvable everywhere. Same store, same key.
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

    # Treat a substituter error (DNS failure, timeout, 5xx) as a soft failure
    # and continue to the next substituter or build from source.
    fallback = true;

    # Fail fast on unreachable substituters (default is ~30 s).
    connect-timeout = 5;
  };
}
