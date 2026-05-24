{ ... }:

{
  imports = [
    ./common/default.nix
    ./darwin/default.nix
  ];

  # Darwin-specific user configuration
  home.username = "mathewalex";
  home.homeDirectory = "/Users/mathew";

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
