{ pkgs, ... }:

{
  # Common packages across all systems
  home.packages = with pkgs; [
    # Core utilities
    git
    curl
    wget
    tree
    jq
    ripgrep
    fd
    bat
    eza
    htop
    unzip
    zip

    # Development essentials
    python3
    rustc
    cargo
    go
    gcc
    gnumake

    # Text editors and tools
    tmux
  ];

  # Common environment variables
  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Git configuration (update email as needed)
  programs.git = {
    enable = true;
    userName = "Vysakh Premkumar";
    userEmail = "vysakhpr218@gmail.com";  # Update this with your actual email
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Shell configurations
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      share = true;
    };
    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 100000;
    extraConfig = ''
      # Enable mouse mode
      set -g mouse on

      # Set prefix to Ctrl-a
      set -g prefix C-a
      unbind C-b
      bind-key C-a send-prefix

      # Split panes using | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Reload config file
      bind r source-file ~/.tmux.conf
    '';
  };

  # XDG directories
  xdg.enable = true;
}
