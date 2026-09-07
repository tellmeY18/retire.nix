# hosts/skywalker/configuration.nix — entry point.
#
# skywalker is a bare-metal x86_64 desktop (Ryzen 3 3300X, 8 GB RAM,
# GTX 1060 6GB) used as a dedicated GPU compute box. Minimal install:
# no desktop, no k3s — just boot, network, SSH, ZFS, and the NVIDIA
# driver stack.
{ ... }:
{
  imports = [
    ../../profiles/base.nix
    ../../profiles/zfs.nix
    ./default.nix
  ];

  networking = {
    hostName = "skywalker";
    hostId = "c3cb4ad2"; # required for ZFS
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  # Required for the NVIDIA proprietary driver + CUDA.
  nixpkgs.config.allowUnfree = true;
}
