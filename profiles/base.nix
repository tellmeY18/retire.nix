# profiles/base.nix — applied to every host
#
# Provides the absolute baseline: nix daemon settings, flakes,
# and a minimal set of CLI tools that should exist everywhere.
{ lib, pkgs, ... }:
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

  # Require password for sudo. If passwordless is needed for automation,
  # use a targeted sudoers rule instead of blanket NOPASSWD.
  security.sudo = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Common packages available on all systems
  environment.systemPackages = with pkgs; [
    vim # emergency editing
    curl # health checks
    htop # process monitoring
    jq # JSON parsing in scripts
  ];
}
