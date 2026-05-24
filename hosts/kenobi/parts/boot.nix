# OCI aarch64 VM boot configuration.
# UEFI + systemd-boot + ZFS.
{ ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
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
