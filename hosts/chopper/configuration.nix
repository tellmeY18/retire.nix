{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix # auto-generated swap, root, home, nix, var
    ./disko-config.nix # pure Disko spec (no function wrapper) :contentReference[oaicite:1]{index=1}
    ../../modules/zfs.nix # ZFS in initrd & filesystem support
    ../../modules/nextcloud.nix # ZFS in initrd & filesystem support
    ../../modules/cockpit.nix # ZFS in initrd & filesystem support
    ../../modules/conduit.nix # ZFS in initrd & filesystem support
    ../../modules/arr.nix
    ../../modules/esp.nix # installer-time ESP & swap mounts
    ./default.nix # bootloader, networking, users, ZFS overrides
  ];

  # Core system settings
  networking.networkmanager.enable = true;
  networking.hostName = "chopper";
  networking.hostId = "91d4eb37";


  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "conduwuit-0.4.6"
  ];
  # Enable Flakes for future rebuilds (via /etc/nix/nix.conf)
  nix = {
    # (optional) use the nix-with-flakes package on NixOS 22.05+
    # package = pkgs.nixFlakes;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };


  # Grant wheel group passwordless sudo
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
