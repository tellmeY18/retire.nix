# profiles/hyprland-minimal.nix — Hyprland session for Vysakh.
#
# System side only: the compositor, polkit and keyring. All theming and
# user tools live in home/vysakh/default.nix as home-manager modules.
# The login manager is chosen per host.
{ ... }:
{
  programs.hyprland.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
