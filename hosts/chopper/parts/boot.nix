{ pkgs, lib, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      # Cap retained boot entries. Without this the ESP grows without bound:
      # kenobi accumulated 42 generations against a 511 MB ESP, hit 86%% full,
      # and `just deploy` failed mid-activation with
      # "OSError: [Errno 28] No space left on device / Failed to install
      # bootloader" — which rolls the whole deploy back.
      #
      # Kernels/initrds are ~85 MB each here (ZFS initrd), though consecutive
      # generations usually share a kernel, so this bounds entries more than
      # bytes. 5 still leaves several rollback targets.
      systemd-boot.configurationLimit = 5;
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
