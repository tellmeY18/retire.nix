{ ... }:
{
  system.stateVersion = "24.11";

  imports = [
    ./sops.nix
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/power.nix
    ./parts/display.nix
    ./parts/virtualisation.nix
    ./parts/programs.nix
    ./parts/users.nix
    ./parts/services.nix
  ];
}
