{ lib, pkgs, ... }:

{
  # NixOS-specific packages - only install on Linux
  home.packages = lib.optionals pkgs.stdenv.isLinux (
    with pkgs;
    [
      # GUI applications (firefox managed by programs.firefox in common/)

      # System monitoring
      iotop
      lsof
      strace
      nethogs
      ncdu

      # Network tools
      nmap
      netcat
      tcpdump
      wireshark-cli

      tree
    ]
  );
}
