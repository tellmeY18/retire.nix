{ ... }:

let
  vysakhMeta = import ../../../users/vysakh.nix;
in
{
  programs = {
    lazygit.enable = true;
    direnv.enable = true;
    tmux.enable = true;
    bat.enable = true;

    zsh = {
      enable = true;
      autosuggestions = {
        enable = true;
        async = true;
      };
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [
          "git"
          "python"
          "man"
          "direnv"
          "systemd"
          "docker-compose"
          "docker"
          "extract"
          "history"
          "battery"
          "timer"
        ];
        theme = "jonathan";
      };
      enableLsColors = true;
      enableGlobalCompInit = true;
    };

    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
      # Idiomatic: keep the flake in a user-owned directory, not /etc/nixos.
      # This sets NH_OS_FLAKE so `nh os switch` works from anywhere
      # without needing sudo to read the flake.
      # See: https://github.com/nix-community/nh#nixos
      flake = "/home/vysakh/nix-config";
    };

    git = {
      enable = true;
      config = [
        { user.name = vysakhMeta.fullName; }
        { user.email = vysakhMeta.email; }
      ];
    };
  };
}
