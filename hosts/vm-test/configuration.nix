# hosts/vm-test/configuration.nix
# Minimal NixOS host to validate auto-discovery and metadata abstractions.
# This host can be built in a VM with: nix build .#nixosConfigurations.vm-test.config.system.build.toplevel
{ ... }:
{
  # Minimal boot config for evaluation
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Minimal filesystem (needed for evaluation)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Minimal networking
  networking = {
    hostName = "vm-test";
    hostId = "deadbeef";
  };

  # Basic settings
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
