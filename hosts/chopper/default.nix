{ config, pkgs, lib, ... }:

let
  statePrivate = "/var/lib/private/technitium-dns-server";
in

{
  # Set the system state version for NixOS upgrades
  system.stateVersion = "24.11";

  ####################
  # Bootloader Setup #
  ####################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  ####################
  # ZFS Overrides    #
  ####################
  boot.zfs.package = lib.mkForce pkgs.zfs_unstable;
  boot.zfs.forceImportAll = lib.mkForce true;

  ####################
  # Users & SSH      #
  ####################
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = true;
      X11UseLocalhost = false; # Allows remote X connections
      PubkeyAuthentication = true;
    };
  };

  ####################
  # Display Manager  #
  ####################
  services.displayManager.ly.enable = true;

  ####################
  # Tailscale VPN    #
  ####################
  services.tailscale = {
    enable = true;
    authKeyFile = "/etc/tailscale/auth.key"; # path to your pre-auth key
    extraUpFlags = [
      "--accept-routes"
      "--advertise-exit-node"
    ];
    openFirewall = true;
  };

  # Provide Tailscale auth key from user home (ensure this file exists and is secured)
  environment.etc."tailscale/auth.key".source = "/home/vysakh/tail.key";

  # Trust the Tailscale interface (optional if openFirewall=true)
  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
    enable = true;
    allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
  };

  ####################
  # Power Management  #
  ####################
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  services.nextcloud = {
    enable = true;
    hostName = "next.tellmey.tech";

    # Manually increment with every major upgrade.
    package = pkgs.nextcloud31;

    # Let NixOS install and configure the database automatically.
    database.createLocally = true;

    # Let NixOS install and configure Redis caching automatically.
    configureRedis = true;

    # Increase the maximum file upload size to avoid problems uploading videos.
    maxUploadSize = "16G";

    https = true;

    autoUpdateApps.enable = true;

    extraAppsEnable = true;

    extraApps = with config.services.nextcloud.package.packages.apps; {
      tasks = tasks;
      contacts = contacts;
      memories = memories;
    };

    settings = {
      overwriteprotocol = "https";
      default_phone_region = "IN";
      port = "8789";
    };

    # Additional Nextcloud configuration
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/home/vysakh/entepass";
    };
  };

  ####################
  # User Programs    #
  ####################
  programs = {
    lazygit.enable = true;
    sway.enable = true;
    zsh = {
      enable = true;
      autosuggestions = {
          enable = true;
          async = true;
      };
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      ohMyZsh = {
          enable = true;
          plugins = [ "git" "python" "man" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "direnv" "systemd" "docker-compose" "docker" "nix" "nixpkgs-fmt" "nix-direnv" ];
          theme = "jonathan";
      };
      enableLsColors = true;
      enableGlobalCompInit = true;
    };
    direnv.enable = true;
    tmux.enable = true;
    bat.enable = true;
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/etc/nixos";
    };
    git = {
      enable = true;
      config = [
        { user.name = "Vysakh Premkumar"; }
        { user.email = "vysakhpr218@gmail.com"; }
      ];
    };
  };

  ####################
  # User Accounts    #
  ####################
  users.users.vysakh = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5"
    ];
    packages = with pkgs; [ opentofu ];
  };

  ####################
  # Cloudflare Tunnel#
  ####################
  services.cloudflared = {
    enable = true;
    tunnels = {
      "b0ca1206-1d09-4892-9d69-d3a196877013" = {
        credentialsFile = "/home/vysakh/.cloudflared/b0ca1206-1d09-4892-9d69-d3a196877013.json";
        default = "http_status:404";
        ingress = {
          "next.tellmey.tech" = { service = "http://localhost:80"; };
          "chat.tellmey.tech" = { service = "http://localhost:6167"; };
          "school.tellmey.tech" = { service = "http://localhost:7000"; };
        };
      };
    };
  };




  ####################
  # Maintenance      #
  ####################
  # System packages are now defined in packages/chopper/system-packages.nix

  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
}
