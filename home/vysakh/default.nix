# home/vysakh/default.nix — vysakh on chopper (to become the work profile).
{ ... }:
{
  imports = [
    ../desktop/hyprland.nix
    ../admin.nix
  ];

  home.stateVersion = "26.11";
}
