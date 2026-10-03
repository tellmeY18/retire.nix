# profiles/gnome-desktop.nix — plain GNOME desktop + Chrome.
#
# Simple-stupid office workstation profile: GDM + GNOME, Chrome as the
# standard browser. No tiling WM, no extensions, no tuning — this is for
# a user who just wants to log in and browse/use office apps.
{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    google-chrome
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (pkgs.lib.getName pkg) [ "google-chrome" ];
}
