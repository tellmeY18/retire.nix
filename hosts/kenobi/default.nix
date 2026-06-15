{ ... }:
{
  system.stateVersion = "25.11";

  imports = [
    ./sops.nix
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/users.nix
    ./parts/k3s.nix
    ./parts/storage.nix
    ../../profiles/zram.nix
  ];

  # ZRAM swap — compressed RAM swap for memory pressure relief.
  # lz4 for speed on ARM (2 vCPU); 30% = ~3.6GB ZRAM on 12GB RAM.
  profiles.zram = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 30;
  };
}
