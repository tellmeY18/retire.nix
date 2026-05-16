{ ... }:
{
  system.stateVersion = "25.11";

  imports = [
    ./sops.nix
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/users.nix
    ./parts/k3s.nix
  ];
}
