{ ... }:
{
  imports = [
    ../../profiles/base.nix
    ../../profiles/k3s-compute-node.nix
    ./default.nix
  ];

  networking = {
    hostName = "r2d2";
    hostId = "f5074045";
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    substituters = [
      "https://tellmey18.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "tellmey18.cachix.org-1:udK9FzY4ZOHz4OapcTUHkwb/b10+5eQzCi44ZA6oFLw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
