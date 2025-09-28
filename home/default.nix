{ lib, pkgs, ... }:

{
  imports = [
    ./common/default.nix
    ./darwin/default.nix
    ./chopper/default.nix
  ];

  # Set user and home directory based on the system
  home.username = if pkgs.stdenv.isDarwin then "mathewalex" else "vysakh";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/mathew" else "/home/vysakh";

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
