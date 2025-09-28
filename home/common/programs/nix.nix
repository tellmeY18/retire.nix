{ config, pkgs, ... }:

{
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
}
