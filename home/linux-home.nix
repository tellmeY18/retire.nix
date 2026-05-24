{ ... }:

{
  imports = [
    ./common/default.nix
    ./chopper/default.nix
  ];

  # Linux-specific user configuration
  home.username = "vysakh";
  home.homeDirectory = "/home/vysakh";

  # Common environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # XDG directories
  xdg.enable = true;

  # Set the state version
  home.stateVersion = "24.05";
}
