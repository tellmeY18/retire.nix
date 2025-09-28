{ config, pkgs, ... }:

{
  imports = [
    ./packages/default.nix
    ./git/default.nix
    ./zsh/default.nix
    ./tmux/default.nix
    ./direnv/default.nix
    ./fzf/default.nix
    ./programs/nix.nix
    ./kitty/default.nix
  ];
}
