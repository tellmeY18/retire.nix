{ pkgs, ... }:

{
  # NixOS-specific packages
  home.packages = with pkgs; [
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
  ];
}
