{ ... }:
{
  imports = [
    ../../profiles/base.nix
    ../../modules/binary-cache.nix
    ../../profiles/k3s-compute-node.nix
    ./default.nix
  ];

  networking = {
    hostName = "kenobi";
    hostId = "a1b2c3d4";
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  # substituters + keys provided by modules/binary-cache.nix
}
