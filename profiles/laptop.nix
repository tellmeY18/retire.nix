# profiles/laptop.nix — power management for portable machines
#
# Thin profile providing laptop-appropriate defaults: TLP for battery,
# lid-switch handling, and NetworkManager for wifi.
#
# Host-specific TLP tuning (governor thresholds, charge limits, etc.)
# belongs in hosts/<name>/parts/power.nix which can layer on top with
# more specific settings.
{ pkgs, ... }:
{
  # TLP for battery management
  services.tlp.enable = true;

  # Ignore lid switch (user manages via WM or manual suspend)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # NetworkManager for wifi
  networking.networkmanager.enable = true;

  # Useful laptop packages
  environment.systemPackages = with pkgs; [
    powertop
  ];
}
