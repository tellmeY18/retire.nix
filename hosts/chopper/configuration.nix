{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/zfs.nix
    ../../modules/nextcloud.nix
    ../../modules/conduit.nix
    ../../modules/arr.nix
    ../../modules/esp.nix
    ./default.nix
    ../../packages/chopper
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
