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
      # TODO: This assumes the repo is checked out at /etc/nixos.
      # Let nh discover the flake automatically, or use a per-host variable.
      flake = "/etc/nixos";
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
