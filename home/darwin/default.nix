{ pkgs, ... }:

{
  imports = [
    ./packages/default.nix
    ./zsh/default.nix
  ];
}
