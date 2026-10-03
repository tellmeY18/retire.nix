# hosts/skywalker/parts/home.nix — Home Manager for vysakh (Hyprland desktop).
{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.vysakh = import ../../../home/vysakh;
  };
}
