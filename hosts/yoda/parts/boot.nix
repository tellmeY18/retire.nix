# hosts/yoda/parts/boot.nix — OCI x86_64 VM boot configuration.
# UEFI + systemd-boot + ZFS + QEMU/virtio.
#
# OCI x86_64 instances boot via UEFI and expose a serial console on ttyS0
# (ARM instances like kenobi use ttyAMA0 instead).
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

    # OCI serial console (x86 uses ttyS0) + local VGA.
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
    ];

    # initrd modules for OCI KVM/QEMU virtio + SCSI block volume.
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "virtio_net"
      "sd_mod"
      "sr_mod"
    ];
  };
}
