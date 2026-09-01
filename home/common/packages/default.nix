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
    nil
    cargo
    go
    gcc
    gnumake
    libiconv

    # Text editors and tools
    vim
    nano

    # Additional development tools
    nix-index # Locate packages providing a file
  ];
}
