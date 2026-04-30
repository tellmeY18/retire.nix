{ lib, pkgs, ... }:

{
  imports = [
    ./packages/default.nix
    ./sway/default.nix
    ../common/packages/dev-k8s.nix
  ];

  # NixOS-specific environment variables
  home.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    BROWSER = "firefox";
    TERM = "xterm-256color";
    PAGER = "less -R";
  };
}
