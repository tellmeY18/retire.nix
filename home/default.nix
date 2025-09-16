{ pkgs, system, ... }:

let
  # Determine the appropriate configuration based on the system
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isNixOS = system == "x86_64-linux" || system == "aarch64-linux";

  # User-specific settings
  darwinUser = "mathewalex";
  nixosUser = "vysakh";

  darwinHome = "/Users/${darwinUser}";
  nixosHome = "/home/${nixosUser}";

in
{
  imports = [
    # Import common configuration for all systems
    ./common/default.nix
  ] ++ (
    # Conditionally import system-specific configurations
    if isDarwin then [ ./darwin/default.nix ]
    else if isNixOS then [ ./chopper/default.nix ]
    else [ ]
  );

  # Set user and home directory based on the system
  home.username = if isDarwin then darwinUser else nixosUser;
  home.homeDirectory = if isDarwin then darwinHome else nixosHome;

  # Set the state version
  home.stateVersion = "24.05";
}
