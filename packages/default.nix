# packages/default.nix — custom package set
#
# Usage:
#   Consumed by overlays/default.nix via callPackage.
#   Platform-specific packages are under packages/<platform>/.
{
  # Platform package sets (imported by their respective host configs)
  darwin = import ./darwin;
}
