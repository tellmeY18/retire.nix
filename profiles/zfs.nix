# profiles/zfs.nix — ZFS support, maintenance, and tooling
#
# Enables the ZFS kernel module in initrd, declares supported
# filesystems, and turns on periodic scrub + TRIM.
#
# Host-specific ZFS settings (pool names, forceImportAll, kernel
# package pinning) belong in hosts/<name>/parts/ or modules/zfs.nix.
{ pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "zfs" ];
  boot.supportedFilesystems = [
    "zfs"
    "vfat"
  ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  environment.systemPackages = with pkgs; [
    zfs
    zfstools
  ];
}
