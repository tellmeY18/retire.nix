{ lib, pkgs, ... }:

{
  # NixOS-specific packages - only install on Linux
  home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    # GUI applications
    firefox
    chromium

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

    # Additional development tools for Linux
    docker
    docker-compose
    sqlite
    postgresql
    redis

    # Linux-specific utilities
    xclip
    tree
  ]);
}
