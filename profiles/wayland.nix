# profiles/wayland.nix — Wayland desktop with Sway + greetd
#
# Sets up a complete graphical session: Sway compositor, tuigreet
# login screen, gnome-keyring for secrets, polkit for privilege
# escalation, and swaylock PAM integration.
#
# Host-specific display tweaks (monitor layout, scaling, etc.)
# belong in hosts/<name>/parts/display.nix.
{ pkgs, ... }:
{
  programs.sway.enable = true;
  programs.dconf.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
      user = "greeter";
    };
  };

  services.gnome.gnome-keyring.enable = true;

  security.polkit.enable = true;
  security.pam.services.swaylock = { };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    grim
    mako
    slurp
    sway
    wl-clipboard
  ];
}
