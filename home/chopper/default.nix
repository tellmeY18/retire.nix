{ lib, pkgs, ... }:

{
  imports = [
    ./packages/default.nix
    ./zsh/default.nix
    ./sway/default.nix
  ];

  # NixOS-specific environment variables
  home.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    BROWSER = "firefox";
    TERM = "xterm-256color";
    PAGER = "less -R";
  };
}

