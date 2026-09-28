# hosts/r2d2/parts/boot.nix — OVMF/UEFI + systemd-boot + ZFS + QEMU virtio
#
# NOTE: This VM is currently running SeaBIOS. The Proxmox VM must be switched
# to OVMF (UEFI) BEFORE running nixos-anywhere. The switch takes effect on
# the next cold boot — kexec bypasses firmware, so the running session is
# unaffected. After nixos-anywhere + reboot, OVMF finds systemd-boot on the ESP.
#
# Proxmox UI: Options → BIOS → OVMF (UEFI), Machine → q35, add EFI Disk
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

    # Proxmox/QEMU serial console + virtio modules
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
    ];
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
