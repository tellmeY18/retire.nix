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
    ../../modules/services/cloudflared-bootstrap.nix
    ../../modules/services/cloudflared-dns.nix
    ../../profiles/k3s-storage-node.nix
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
    # conduwuit 0.4.6 is flagged insecure upstream but is the latest available.
    # Track upgrade: https://github.com/girlbossceo/conduwuit
    # TODO: Remove once a non-insecure version is packaged in nixpkgs.
    permittedInsecurePackages = [
      "conduwuit-0.4.6"
    ];
  };
  nix = {
    settings = {
      trusted-users = [
        "root"
        "vysakh"
      ];
      substituters = [
        "https://tellmey18.cachix.org"
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "tellmey18.cachix.org-1:udK9FzY4ZOHz4OapcTUHkwb/b10+5eQzCi44ZA6oFLw="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
