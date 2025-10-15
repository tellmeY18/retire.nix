{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/zfs.nix
    ../../modules/nextcloud.nix
    ../../modules/care.nix
    ../../modules/conduit.nix
    ../../modules/arr.nix
    ../../modules/neondb.nix
    ./default.nix
    ../../packages/chopper
  ];

  # Core system settings
  networking = {
    networkmanager = {
      enable = true;
    };
    hostName = "chopper";
    hostId = "91d4eb37";
  };


  time = {
    timeZone = "Asia/Kolkata";
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "conduwuit-0.4.6"
    ];
  };
  nix = {
    settings.trusted-users = [ "root" "vysakh" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };


  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
}
