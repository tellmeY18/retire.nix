{ config, pkgs, ... }:
{
  ####################
  # NeonDB           #
  ####################
  services.neondb = {
    enable = false;
    package = pkgs.neondb-bin;
    tenant = "default";
    dataDir = "/var/lib/neondb";
  };

  ####################
  # OpenSSH          #
  ####################
  services.openssh = {
    enable = true;
    settings = {
      # Root login via SSH key only — password auth globally disabled.
      # If you don't need root SSH at all, set to "no".
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = true;
      X11UseLocalhost = false; # Allows remote X connections
      PubkeyAuthentication = true;
    };
  };

  ####################
  # Care             #
  ####################
  services.care = {
    enable = false;
    django.allowedHosts = [ "localhost" ];
    cors.allowedOrigins = [ "https://example.com" ];
    database.createLocally = true;
  };

  ####################
  # Tailscale VPN    #
  ####################
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    extraUpFlags = [
      "--accept-routes"
      "--advertise-exit-node"
      "--accept-dns"
      # Advertise this node's pod CIDR so other nodes can route to our pods
      "--advertise-routes=10.42.0.0/24"
    ];
    openFirewall = true;
  };

  ####################
  # Nextcloud        #
  ####################
  services.nextcloud = {
    enable = false;
    hostName = "next.tellmey.fyi";

    # Manually increment with every major upgrade.
    package = pkgs.nextcloud33;

    database.createLocally = true;
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

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud-admin-pass";
    };
  };

  ####################
  # Cloudflare Tunnel#
  ####################
  # Disabled: cloudflared fails to build on nixpkgs-unstable
  # (test flake in management/events_test.go). Re-enable once upstream
  # fixes the panic-in-goroutine issue.
  services.cloudflared = {
    enable = false;
  };

  ####################
  # ZFS Maintenance  #
  ####################
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };
}
