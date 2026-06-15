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
    ./parts/k3s.nix
    ../../profiles/zram.nix
  ];

  # ZRAM swap — compressed RAM swap for memory pressure relief.
  # zstd gives good compression on x86; 50% = ~4GB ZRAM on 8GB RAM.
  profiles.zram = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
