{ config, pkgs, ... }:

{
  # Ensure ZFS (and vfat) are available in the initrd
  boot.initrd.availableKernelModules = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" "vfat" ];
}

