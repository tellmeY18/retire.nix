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
}
