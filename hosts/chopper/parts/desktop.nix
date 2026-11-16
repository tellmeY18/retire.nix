# hosts/chopper/parts/desktop.nix — Hyprland daily-driver desktop.
#
# Theme and user apps: home/vysakh (paper/ink monochrome, from skywalker).
{ config, lib, pkgs, ... }:
{
  imports = [ ../../../profiles/hyprland-minimal.nix ];

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.hyprland.package}/bin/start-hyprland";
      user = "greeter";
    };
  };

  # Audio for the volume keys / waybar (wpctl).
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # hyprlock needs a PAM service to unlock.
  security.pam.services.hyprlock = { };

  # Bluetooth (+ blueman applet/manager in the session).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Removable media (udiskie in the session), GTK settings store (the
  # light/dark color-scheme), power profiles for the bar.
  services.udisks2.enable = true;
  programs.dconf.enable = true;

  # Workstation, not a server: suspend on lid close (hypridle locks first).
  # Overrides profiles/server-laptop-power.nix, which ignores the lid.
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "suspend";
    HandleLidSwitchExternalPower = lib.mkForce "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Brightness keys (brightnessctl) without sudo.
  users.users.vysakh.extraGroups = [ "video" ];
}
