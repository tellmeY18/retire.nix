# hosts/c3po/default.nix — Minimal NixOS config for nixos-anywhere.
# Just enough to boot, SSH in, connect to Tailscale, and have ZFS.
# Everything else gets added via deploy-rs later.
{ config, pkgs, ... }:
{
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ./sops.nix
    ./parts/k3s.nix
    ./parts/network.nix
    ../../profiles/k3s-storage-node.nix
    ../../profiles/zfs-openebs-datasets.nix
  ];

  # Boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # ZFS support
    supportedFilesystems = [ "zfs" ];
    zfs.extraPools = [ "rpool" ];
  };

  # ZFS
  networking.hostId = "663cc5c7"; # required for ZFS (8 hex chars)

  # Networking — WiFi + basic firewall (extended in parts/network.nix)
  networking = {
    hostName = "c3po";
    wireless = {
      enable = true;
    };
    useDHCP = true;
  };

  # SSH — essential for deploy-rs
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Root SSH key — so deploy-rs can reach us
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGk3YWoVOSFBLrr3ir00EJRcFbVMBn35DrlRaFPjBmh+ vysakh@chopper"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgedb3cJt6ID0W2c8Fzgb+58tz/qWvuoAR3xmp1WHQZ mathewalex@Vysakhs-MacBook-Pro"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5"
  ];

  # Tailscale config is in parts/network.nix

  # Nix settings — community caches for faster builds
  nix.settings = {
    trusted-users = [ "root" ];
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
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Minimal packages — just enough to be useful
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    tmux
  ];

  # Locale & timezone
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11";
}
