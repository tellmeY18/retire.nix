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
      # Must be true when forceImportAll is true (assertion added in nixpkgs 26.11).
      forceImportRoot = lib.mkForce true;
    };
  };
}
