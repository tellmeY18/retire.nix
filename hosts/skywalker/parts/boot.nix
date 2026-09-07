# hosts/skywalker/parts/boot.nix — bare-metal x86_64 desktop boot.
# UEFI + systemd-boot + root-on-ZFS.
#
# NOTE: the installer USB must be booted in UEFI mode. Booting it in legacy
# BIOS mode leaves /sys/firmware/efi absent and systemd-boot cannot install.
{ ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10; # 238 GB disk — don't hoard kernels
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    supportedFilesystems = [ "zfs" ];
    # 26.11's new default. This box owns its pool outright; force-importing a
    # pool that another system may have left dirty is a data-loss footgun with
    # nothing to gain here.
    zfs.forceImportRoot = false;

    # ZFS ARC cap — 1 GiB. The default is 50% of RAM (~3.8 GB here). Even the
    # 2 GiB this started at was too generous: measured ARC sat pinned at its
    # cap while only 8 GB total exists, and on an inference box every spare
    # GB is model weights, KV cache, or a dataset being staged. The NVMe does
    # ~1.9 GB/s on direct reads, so a smaller cache costs very little —
    # model files are read once at load, which ARC cannot help with anyway.
    # Raise this after the RAM upgrade.
    kernelParams = [ "zfs.zfs_arc_max=1073741824" ];

    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    kernelModules = [ "kvm-amd" ];
  };

  # AMD microcode updates.
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
