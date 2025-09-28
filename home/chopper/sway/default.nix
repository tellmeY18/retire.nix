{ config, pkgs, ... }:

{
  programs.sway= {
    enable = true;
    pkg = pkgs.swayfx
  };
}

