{ pkgs ? import <nixpkgs> { } }:
let
  env = pkgs.buildEnv {
    name = "test-apps";
    paths = with pkgs; [ firefox-bin kitty ];
    pathsToLink = [ "/Applications" ];
  };
in
env
