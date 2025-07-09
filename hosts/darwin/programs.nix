{ pkgs, ... }: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableFastSyntaxHighlighting = true;
      enableFzfCompletion = true;
      enableFzfGit = true;
      enableFzfHistory = true;
      enableGlobalCompInit = true;
    };
    direnv = {
      enable = true;
    };
    vim = {
      enable = true;
      enableSensible = true;
    };
    nix-index = {
      enable = true;
    };
  };
}
