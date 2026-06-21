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
