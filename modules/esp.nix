{ config, lib, ... }:

{
  # During installer phase, mount ESP & swap under /mnt
  fileSystems."/boot/efi" = {
    device = lib.mkDefault "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [ "noatime" ];
  };

  swapDevices = [
    { device = lib.mkDefault "/dev/disk/by-partlabel/swap"; }
  ];
}

