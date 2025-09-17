{ lib, pkgs, ... }:

{
  imports = [
    ./packages/default.nix
    ./zsh/default.nix
  ];

  # Darwin-specific environment variables
  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    BROWSER = "firefox";
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
  };
}
