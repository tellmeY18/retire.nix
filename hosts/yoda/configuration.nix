# hosts/yoda/configuration.nix — entry point (phase 1: bootstrap).
#
# yoda is an Oracle Cloud (OCI) KVM x86_64 VM — the intended 4th k3s node.
# This phase installs ONLY a bare-minimum, bootable NixOS on ZFS that is
# reachable over the OCI public IP. No Tailscale, no sops, no k3s — those are
# added post-bootstrap (phase 2) once the age key + secrets exist.
#
# Phase 2 will add here:
#   imports = [ ../../profiles/k3s-compute-node.nix ... ];
{ ... }:
{
  imports = [
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
