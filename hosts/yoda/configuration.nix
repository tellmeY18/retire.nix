# hosts/yoda/configuration.nix — entry point (phase 2).
#
# yoda is an Oracle Cloud (OCI) KVM x86_64 VM — the 4th k3s node, a compute
# (agent) worker on the tailnet. The compute-node profile declares the
# services.k3s-cluster options and applies the compute node labels; the agent
# itself is enabled in parts/k3s.nix once the node's Tailscale IP is known.
{ ... }:
{
  imports = [
    ../../profiles/k3s-compute-node.nix
    ./default.nix
  ];

  networking = {
    hostName = "yoda";
    hostId = "8c95266a";
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    trusted-users = [
      "root"
      "vysakh"
    ];
    substituters = [
      "https://tellmey18.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "tellmey18.cachix.org-1:udK9FzY4ZOHz4OapcTUHkwb/b10+5eQzCi44ZA6oFLw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    experimental-features = "nix-command flakes";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
