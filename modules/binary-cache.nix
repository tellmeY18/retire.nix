# Binary cache configuration — shared across all hosts.
#
# Substituters: cache.nixos.org plus a few community cachix caches, so
# common packages are pulled pre-built instead of compiled locally.
#
# Fallback behaviour:
#   fallback = true  — if a substituter errors (DNS failure, 5xx, timeout),
#                      nix tries the next one and ultimately builds from source.
#   connect-timeout = 5  — fail fast on unreachable substituters instead of
#                          blocking for the default 30 s.
{ ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      # Popular community binary caches
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://deploy-rs.cachix.org"
      "https://cachix.cachix.org"
      "https://tellmey18.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # Popular community binary caches
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "deploy-rs.cachix.org-1:WfYy4n/FmMUOR55R4BcI04+CLy18CXsMJMIRhDw3hOw="
      "cachix.cachix.org-1:myoobmXM2d/eFGhO/9rE8cVoEPCFU1N2aR2YmZ77Rso="
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
