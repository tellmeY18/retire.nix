# OCI aarch64 VM boot configuration.
# UEFI + systemd-boot + ZFS.
{ ... }:
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

    # ZFS support
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = true;

    # OCI serial console access (ARM uses ttyAMA0)
    kernelParams = [
      "console=ttyAMA0,115200"
      "console=tty1"
    ];

    # initrd modules for OCI virtio devices
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "virtio_net"
    ];
  };
}
