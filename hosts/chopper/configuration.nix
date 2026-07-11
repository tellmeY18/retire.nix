{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../profiles/base.nix
    ../../modules/zfs.nix

    ../../modules/services/cloudflared-bootstrap.nix
    ../../modules/services/cloudflared-dns.nix
    ../../profiles/k3s-storage-node.nix
    ../../profiles/zfs-openebs-datasets.nix
    ./default.nix
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
  };
}
