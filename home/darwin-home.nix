{ ... }:

{
  imports = [
    ./common/default.nix
    ./darwin/default.nix
  ];

  # Darwin-specific user configuration
  home.username = "mathewalex";
  home.homeDirectory = "/Users/mathew";

  # Common environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # gomuks Matrix client (Darwin-only)
  programs.gomuks.enable = true;

  # Ghostty terminal (darwin-only)
  # Package is null because Ghostty is installed via Homebrew cask.
  # Config lives at ~/.config/ghostty/config, generated from Nix.
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;

    # SATANIC PALETTE — matches the Kitty config theme
    # FreeBSD devil-inspired: void blacks, crimson reds, gold accents
    settings = {
      # Font
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;

      # Colors — Satanic palette
      foreground = "d4c5d4";
      background = "0a0a0f";
      cursor-color = "c12127";
      cursor-text = "0a0a0f";
      selection-foreground = "d4c5d4";
      selection-background = "3a1a2a";

      palette = [
        "0=#0a0a0f" # black
        "1=#c12127" # red
        "2=#4a9c6f" # green
        "3=#d4a84b" # yellow
        "4=#4a6a9c" # blue
        "5=#7a4a8a" # magenta
        "6=#4a9c9c" # cyan
        "7=#d4c5d4" # white
        "8=#14101a" # bright black
        "9=#e63946" # bright red
        "10=#5abc7f" # bright green
        "11=#e8c05b" # bright yellow
        "12=#5a8abe" # bright blue
        "13=#9a5aaa" # bright magenta
        "14=#5abeae" # bright cyan
        "15=#f0e0f0" # bright white
      ];

      # Window
      background-opacity = 0.85;
      background-blur-radius = 24;
      window-padding-x = 30;
      window-padding-y = 30;
      confirm-close-surface = false;

      # Cursor
      cursor-style = "beam";
      cursor-style-blink = false;

      # Selection
      copy-on-select = "clipboard";

      # Scrollback
      scrollback-limit = 10000;

      # Shell integration
      shell-integration = "zsh";

      # Mouse
      mouse-hide-while-typing = true;

      # Terminal
      term = "xterm-256color";

      # Clipboard
      clipboard-read = "allow";
      clipboard-write = "allow";

      # Performance
      vsync = true;
    };
  };

  # XDG directories
  xdg.enable = true;

  # Set the state version
  home.stateVersion = "24.05";
}
