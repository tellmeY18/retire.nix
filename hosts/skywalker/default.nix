# hosts/skywalker/default.nix — parts composition.
#
#   boot    : UEFI + systemd-boot, root-on-ZFS
#   network : DHCP on enp6s0 (Realtek r8169), Tailscale, firewall
#   users   : vysakh + root SSH keys
#   nvidia  : proprietary driver + CUDA, headless
#   ai      : Ollama, CUDA-accelerated, tailnet-only
#
# Deliberately absent: desktop, podman. Container workloads run as k3s
# pods on containerd — a second runtime would only duplicate it.
{ lib, ... }:
{
  system.stateVersion = "26.11";

  imports = [
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/users.nix
    ./parts/nvidia.nix
    ./parts/ai.nix
    ../../profiles/zram.nix
  ];

  # ZRAM swap. With 8 GB of RAM and workloads that allocate in multi-GB
  # chunks, the failure mode without this is an OOM kill mid-run. Compressed
  # RAM swap turns that into a slowdown instead. 25% (~2 GB) is deliberately
  # modest: this box wants RAM for models, not for a big compressed pool, and
  # there is a 16 GB disk swap behind it for genuine overflow.
  #
  # zstd, not lz4: 4 cores at 4.35 GHz have compression headroom to spare,
  # and the better ratio is what actually buys usable memory here.
  profiles.zram = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # ── Closure slimming ────────────────────────────────────────────────
  # 8 GB RAM and a 238 GB disk shared with a large CUDA closure — drop
  # everything that isn't needed to boot, SSH in, and run GPU jobs.
  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.info.enable = lib.mkForce false;
  documentation.doc.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  # Don't pin the nixpkgs flake source (~196 MB) into the system closure.
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath = false;

  programs.command-not-found.enable = false;

  # No sound, no printing, no bluetooth on a headless compute box.
  services.pulseaudio.enable = false;
  services.printing.enable = false;
  hardware.bluetooth.enable = false;
}
