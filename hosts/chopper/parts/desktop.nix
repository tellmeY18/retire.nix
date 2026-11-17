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

  # Thunar: themed via the shared GTK config (home/desktop); gvfs/tumbler
  # give trash, mounts and thumbnails.
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Workstation, not a server: suspend on lid close (hypridle locks first).
  # Overrides profiles/server-laptop-power.nix, which ignores the lid.
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "suspend";
    HandleLidSwitchExternalPower = lib.mkForce "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # 1Password GUI + CLI; satan may unlock via system auth (polkit) and
  # the CLI integrates with the desktop app.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "satan" ];
  };
  # Let the desktop app talk to Firefox's 1Password extension; nixpkgs'
  # firefox-bin runs under names 1Password doesn't trust by default.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      firefox-bin
      .firefox-wrapped
    '';
    mode = "0755";
  };

  # Graphical password prompt for `sudo -A`, so non-TTY callers (coding
  # agents) can request root and the user approves via a dialog.
  environment.etc."sudo.conf".text = ''
    Path askpass ${pkgs.writeShellScript "sudo-askpass" ''
      exec ${pkgs.zenity}/bin/zenity --password --title="sudo"
    ''}
  '';

  # Brightness keys (brightnessctl) without sudo.
  users.users.vysakh.extraGroups = [ "video" ];
}
