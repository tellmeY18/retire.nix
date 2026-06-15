# hosts/c3po/default.nix — Minimal NixOS config for nixos-anywhere.
# Just enough to boot, SSH in, connect to Tailscale, and have ZFS.
# Everything else gets added via deploy-rs later.
{ pkgs, ... }:
{
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ./sops.nix
    ./parts/k3s.nix
    ./parts/network.nix
    ./parts/power.nix
    ./parts/swap.nix
    ../../profiles/k3s-storage-node.nix
    ../../profiles/zram.nix
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
    zfs = {
      extraPools = [ "rpool" ];
      forceImportRoot = false; # reduce risk of data loss (new default from 26.11)
    };
  };

  # Networking — NetworkManager (wired LAN primary)
  # Switch done physically: `sudo nixos-rebuild switch --flake github:tellmeY18/retire.nix#c3po`
  networking = {
    hostName = "c3po";
    hostId = "663cc5c7"; # required for ZFS (8 hex chars)
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.enable = false;
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

  # ZRAM swap — compressed RAM swap alongside the ZFS zvol.
  # ZRAM is higher priority (100), so the kernel uses it first.
  # The existing ZFS zvol (/dev/zvol/rpool/swap) is a lower-priority
  # fallback for extreme spikes. zstd gives good compression on x86.
  profiles.zram = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

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

  # Minimal packages + networking utilities
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    tmux
    # Networking management
    networkmanager # provides nmtui, nmcli
    iwd # provides iwctl
    # Networking debugging
    iw # low-level WiFi config
    wirelesstools # iwconfig, iwlist
    ethtool
    traceroute
    dnsutils # dig, nslookup
    nmap
    iperf3
  ];

  # Locale & timezone
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11";
}
