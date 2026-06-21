{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/zfs.nix
    ../../modules/nextcloud.nix
    ../../modules/care.nix
    ../../modules/arr.nix
    ../../modules/neondb.nix
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
  nix = {
    settings = {
      trusted-users = [
        "root"
        "vysakh"
      ];
      experimental-features = "nix-command flakes";
    };
  };

  security.sudo = {
    enable = true;
    # Require password for sudo. If passwordless is needed for automation,
    # use a targeted sudoers rule instead of blanket NOPASSWD.
    wheelNeedsPassword = true;
  };
}
