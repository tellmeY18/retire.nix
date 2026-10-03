# profiles/hyprland-minimal.nix — Hyprland session for Vysakh.
#
# System side only: the compositor, polkit and keyring. All theming and
# user tools live in home/vysakh/default.nix as home-manager modules.
# GDM (gnome-desktop.nix) is untouched; Hyprland just appears as a session.
{ ... }:
{
  programs.hyprland.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
