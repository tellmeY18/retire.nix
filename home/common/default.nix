{ ... }:

{
  imports = [
    ./packages/default.nix
    ./git/default.nix
    ./zsh/default.nix
    ./zed-editor/default.nix
    ./nixvim/default.nix
    #./jujutsu/default.nix
    ./tmux/default.nix
    ./direnv/default.nix
    ./firefox/default.nix
    ./fzf/default.nix
    ./programs/nix.nix
    ./kitty/default.nix
  ];
}
