# Binary cache configuration — shared across all hosts.
#
# Adds the self-hosted Attic cache as a substituter so packages built
# by CI are pulled as pre-built binaries, never compiled locally.
#
# CI (GitHub Actions) uses the public URL since runners are NOT on the
# tailnet. See .github/workflows/build.yml.
#
# Architecture:
#   CI → pushes via https://cache.tellmey.fyi (public Traefik ingress)
#   NixOS nodes → pull via http://attic.tail477f2f.ts.net:8080 (tailnet;
#                 direct WireGuard between cluster peers, full bandwidth).
#                 MagicDNS resolves via systemd-resolved split-DNS (--accept-dns)
#   darwin (mac) → pull via https://cache.tellmey.fyi ONLY (see below)
#
# Why darwin skips the tailnet endpoint:
#   An earlier version of this comment claimed the darwin nix daemon cannot
#   resolve .tail477f2f.ts.net and would silently fall through to the public
#   ingress. That is no longer true — /etc/resolver/tail477f2f.ts.net makes
#   the name resolve, so nix DOES pick the tailnet substituter, and it is
#   dramatically slower: the mac has no direct WireGuard path to the attic
#   node and every byte is relayed through a DERP server
#   (`tailscale ping attic` → "via DERP(blr)", "direct connection not
#   established"). Measured on a 329 MB NAR: ~50 KB/s over the relay vs
#   ~260 KB/s via the public ingress. At 50 KB/s large NARs never finish
#   before nix's stalled-download-timeout (300 s) kills them, producing
#   `HTTP error 200 (curl error: Timeout was reached)` and a spurious
#   fallback to building from source.
#
# Fallback behaviour:
#   fallback = true  — if a substituter errors (DNS failure, 5xx, timeout),
#                      nix tries the next one and ultimately builds from source.
#   connect-timeout = 5  — fail fast on unreachable substituters instead of
#                          blocking for the default 30 s.
#
#   Substituter order (priority):
#     1. cache.nixos.org      — always available, most reliable
#     2. attic tailnet        — NixOS nodes only (direct WireGuard)
#     3. attic public ingress — resolvable everywhere via public DNS
{ pkgs, lib, ... }:
let
  # The mac reaches the tailnet only over a DERP relay, so the tailnet
  # substituter is a pessimisation there rather than a fast path.
  useTailnetCache = !pkgs.stdenv.hostPlatform.isDarwin;
in
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
    ]
    # Direct tailnet endpoint (fast, lowest latency) — NixOS nodes only.
    # They resolve this via systemd-resolved split-DNS (Tailscale routes
    # .ts.net to 100.100.100.100) and have direct WireGuard peering.
    ++ lib.optional useTailnetCache "http://attic.tail477f2f.ts.net:8080/system"
    ++ [
      # Public Traefik ingress — resolvable everywhere. Same store, same key.
      "https://cache.tellmey.fyi/system"
      # Popular community binary caches
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://deploy-rs.cachix.org"
      "https://cachix.cachix.org"
      "https://tellmey18.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "system:mvnfTi6w7gvX6oksJ4JhHLL4wVUa576bgtLJ6lh9C2Y="
      # Popular community binary caches
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "deploy-rs.cachix.org-1:WfYy4n/FmMUOR55R4BcI04+CLy18CXsMJMIRhDw3hOw="
      "cachix.cachix.org-1:myoobmXM2d/eFGhO/9rE8cVoEPCFU1N2aR2YmZ77Rso="
    ];

    # Both attic endpoints serve the same store (signed by the key above).
    # The tailnet URL stays trusted even where it is not a default
    # substituter, so it can still be opted into ad hoc with
    # `--substituters` on a host that does have a direct route.
    trusted-substituters = [
      "http://attic.tail477f2f.ts.net:8080/system"
      "https://cache.tellmey.fyi/system"
    ];

    # Treat a substituter error (DNS failure, timeout, 5xx) as a soft failure
    # and continue to the next substituter or build from source.
    fallback = true;

    # Fail fast on unreachable substituters (default is ~30 s).
    connect-timeout = 5;

    # Don't cache negative lookups — always retry substituters that were
    # temporarily unreachable (useful during initial rollouts).
    narinfo-cache-negative-ttl = 0;
  };
}
