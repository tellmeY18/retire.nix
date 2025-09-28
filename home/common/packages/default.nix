{ pkgs, ... }:

{
  # Common packages across all systems
  home.packages = with pkgs; [
    # Core utilities
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
    vim
    nano

    # Additional development tools
    nix-index # Locate packages providing a file
  ];
}
