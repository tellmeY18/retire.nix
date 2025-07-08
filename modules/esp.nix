{ config, lib, ... }:

{
  # Mount the EFI System Partition (ESP) and configure swap for the installer phase.
  fileSystems."/boot/efi" = {
    device = lib.mkDefault "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [ "noatime" ];
  };

  swapDevices = [
    { device = lib.mkDefault "/dev/disk/by-partlabel/swap"; }
  ];
}
