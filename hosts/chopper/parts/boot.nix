{ pkgs, lib, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    # NOTE: mkForce used because ZFS unstable is required for kernel compat.
    # Track: https://github.com/openzfs/zfs/issues/
    zfs = {
      package = lib.mkForce pkgs.zfs_unstable;
      forceImportAll = lib.mkForce true;
      # New default from 26.11 — reduces risk of data loss by not
      # force-importing the root pool if it wasn't cleanly exported.
      forceImportRoot = false;
    };
  };
}
