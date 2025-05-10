{ config, pkgs, lib, ... }:

let
  statePrivate = "/var/lib/private/technitium-dns-server";
in

{
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
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    X11Forwarding = true;
    X11UseLocalhost = false; # Allows remote X connections
    PubkeyAuthentication = true;
  };


  services.displayManager.ly.enable = true;
  services.tailscale = {
    enable = true; # start tailscaled
    authKeyFile = "/etc/tailscale/auth.key"; # path to your pre-auth key
    extraUpFlags = [
      "--accept-routes" # advertise subnet routes
      "--advertise-exit-node" # offer this node as exit node
    ];
    openFirewall = true; # auto-open UDP port
  };

  # 2. Drop your Tailnet auth key into /etc
  environment.etc."tailscale/auth.key".source = "/home/vysakh/tail.key";

  # 3. Trust the Tailscale interface (optional if openFirewall=true)
  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
  };


  services.logind = {
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  programs = {
    lazygit = {
      enable = true;
    };
    sway = {
      enable = true;
    };
    fish = {
      enable = true;
    };
    direnv = {
      enable = true;
    };
    tmux = {
      enable = true;
    };
    bat = {
      enable = true;
    };
    git = {
      enable = true; # install git and initialize /etc/gitconfig
      config = [
        { user.name = "Vysakh Premkumar"; }
        { user.email = "vysakhpr218@gmail.com"; }
      ];
    };
  };


  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
  };

  users.users.vysakh = {
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5" ];
    packages = with pkgs; [ opentofu ];
  };

  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "b0ca1206-1d09-4892-9d69-d3a196877013" = {
      credentialsFile = "/home/vysakh/.cloudflared/b0ca1206-1d09-4892-9d69-d3a196877013.json";
      default = "http_status:404";
      ingress = {
        "next.tellmey.tech" = {
          service = "http://localhost:80";
        };
        "chat.tellmey.tech" = {
          service = "http://localhost:6167";
        };
        "school.tellmey.tech" = {
          service = "http://localhost:7000";
        };
      };
    };
  };

  services.semaphoreui = {
    enable = true;
    port = 3000;
    webHost = "http://chopper:3000";


    # Open firewall
    openFirewall = true;
  };
  ####################
  # Maintenance      #
  ####################
  environment.systemPackages = with pkgs; [ zfs gemini-cli zfstools vim kitty aria2 go bun comma git riseup-vpn cockpit ];
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
}
