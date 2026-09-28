# Binary cache configuration — shared across all hosts.
#
# Adds the self-hosted Attic cache as a substituter so packages built
# by CI are pulled as pre-built binaries, never compiled locally.
#
# Architecture:
#   CI → pushes via https://cache.tellmey.fyi (public Traefik ingress)
#   every host → pulls via https://cache.tellmey.fyi
#
# Why there is no tailnet endpoint any more:
#   The attic tailnet URL (attic.<tailnet>.ts.net:8080) used to sit ahead of
#   the public ingress for NixOS nodes, on the theory that direct WireGuard
#   beats going out to Traefik. In practice it was a liability:
#
#     - It is served by a Tailscale operator ts-proxy POD. Whenever that pod
#       restarts (operator upgrade, ProxyClass change, node drain) the
#       endpoint vanishes for a minute or two. nix walks substituters in
#       order, so a dead entry at the head cost connect-timeout x retries
#       FOR EVERY PATH — deploys crawled behind thousands of timeouts and
#       looked like they were ignoring the cache entirely.
#     - On darwin it was actively slower: the mac has no direct WireGuard
#       path to the attic node, so every byte went over a DERP relay
#       (~50 KB/s vs ~260 KB/s public). Large NARs hit
#       stalled-download-timeout and fell back to building from source.
#
#   The public ingress is served by Traefik and has no such failure mode.
#   One endpoint, same store, same signing key, no conditional logic.
#
# Fallback behaviour:
#   fallback = true  — if a substituter errors (DNS failure, 5xx, timeout),
#                      nix tries the next one and ultimately builds from source.
#   connect-timeout = 2  — fail fast on unreachable substituters instead of
#                          blocking for the default 30 s.
#
#   Substituter order (priority):
#     1. cache.nixos.org      — always available, most reliable
#     2. attic public ingress — our own builds
{ ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      # Public Traefik ingress — our own builds, same signing key.
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

    trusted-substituters = [
      "https://cache.tellmey.fyi/system"
    ];

    # Treat a substituter error (DNS failure, timeout, 5xx) as a soft failure
    # and continue to the next substituter or build from source.
    fallback = true;

    # Fail fast on unreachable substituters (default is ~30 s). 2 s is
    # plenty for the tailnet and the public ingress alike (both answer in
    # well under 200 ms when healthy) and caps the per-path penalty when
    # one of them is mid-restart.
    connect-timeout = 2;

    # Don't cache negative lookups — always retry substituters that were
    # temporarily unreachable (useful during initial rollouts).
    narinfo-cache-negative-ttl = 0;
  };
}
