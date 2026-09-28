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
