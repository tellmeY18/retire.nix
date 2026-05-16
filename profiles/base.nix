# profiles/base.nix — applied to every host
#
# Provides the absolute baseline: nix daemon settings, flakes,
# and a minimal set of CLI tools that should exist everywhere.
{ pkgs, lib, ... }:
{
  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # Common packages available on all systems
  environment.systemPackages = with pkgs; [
    vim # emergency editing
    curl # health checks
    htop # process monitoring
    jq # JSON parsing in scripts
  ];
}
