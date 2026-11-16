# hosts/chopper/parts/home.nix — Home Manager for vysakh (Hyprland desktop).
{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Pre-existing dotfiles (old standalone HM, ~/.zshrc) are moved aside, not clobbered.
    backupFileExtension = "hm-bak";
    users.vysakh = import ../../../home/vysakh;
  };
}
