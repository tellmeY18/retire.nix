# hosts/chopper/parts/desktop.nix — Hyprland daily-driver desktop.
#
# Theme and user apps: home/vysakh (paper/ink monochrome, from skywalker).
{ config, pkgs, ... }:
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

  # Brightness keys (brightnessctl) without sudo.
  users.users.vysakh.extraGroups = [ "video" ];
}
