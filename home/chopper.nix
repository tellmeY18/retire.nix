{ pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  # NixOS-specific user info
  home.username = "vysakh";
  home.homeDirectory = "/home/vysakh";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # NixOS-specific packages
  home.packages = with pkgs; [

    # System monitoring
    iotop
    lsof
    strace

    # Network tools
    nmap
    netcat

  ];

  # NixOS-specific environment variables
  home.sessionVariables = {
    # Inherit common variables and add Linux-specific ones
    BROWSER = "firefox";
    TERM = "xterm-256color";
  };

  # Linux-specific shell configuration
  programs.zsh = {
    # Inherit common zsh config
    profileExtra = ''
      # Linux-specific configuration
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
