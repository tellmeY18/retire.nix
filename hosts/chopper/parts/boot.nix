{ pkgs, lib, ... }:
{
  services.bootvine.enable = true;

  boot = {
    # Quiet console: no kernel/initrd/systemd chatter before the greeter.
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.systemd.show_status=auto"
      "udev.log_level=3"
      "rd.udev.log_level=3"
    ];
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
