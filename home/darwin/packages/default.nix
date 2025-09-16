{ pkgs, ... }:

{
  # Darwin-specific packages
  home.packages = with pkgs; [
    # macOS-specific tools
    mas  # Mac App Store CLI
    zoxide

    # Additional development tools for macOS
    docker
    docker-compose
  ];
}
