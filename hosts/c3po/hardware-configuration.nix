# hardware-configuration.nix — placeholder for nixos-anywhere.
# nixos-anywhere generates the real one during install.
# This just needs enough to evaluate the flake.
{ modulesPath
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  # WiFi firmware
  hardware.enableRedistributableFirmware = true;
}
