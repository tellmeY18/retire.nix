{ config, lib, ... }:
let
  repoDir = "${config.home.homeDirectory}/.config/nix";
in
{
  xdg.configFile."emacs".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/home/darwin/emacs";
}
