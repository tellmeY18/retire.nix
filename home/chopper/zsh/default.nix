{ lib, pkgs, ... }:

{
  programs.zsh = lib.mkIf pkgs.stdenv.isLinux {
    # Inherit common zsh config
    profileExtra = ''
      # Linux-specific configuration
      export PATH="$HOME/.local/bin:$PATH"

      # Add flatpak support if available
      if [ -d "/var/lib/flatpak/exports/bin" ]; then
        export PATH="/var/lib/flatpak/exports/bin:$PATH"
      fi
    '';
    shellAliases = {
      # Linux-specific aliases
      systemctl = "sudo systemctl";
      journalctl = "sudo journalctl";
      dmesg = "sudo dmesg";
      netstat = "sudo netstat";
      # Docker aliases
      dps = "docker ps";
      dimg = "docker images";
      # System information
      ports = "sudo netstat -tuln";
    };
  };
}
