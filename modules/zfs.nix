{ config, pkgs, lib, ... }:

{
  # Ensure ZFS and vfat are available in the initrd for root-on-ZFS boot
  boot.initrd.availableKernelModules = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" "vfat" ];

  # Use the latest ZFS package if needed (optional, uncomment if you want unstable)
  # boot.zfs.package = pkgs.zfs_unstable;

  # Enable ZFS auto-scrub and trim for maintenance
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # Optional: Enable ZFS event daemon for automatic snapshots, etc.
  # services.zfs.zed.enable = true;

  # Optional: Add ZFS tools to systemPackages for convenience
  environment.systemPackages = with pkgs; [
    zfs
    zfstools
  ];
}
