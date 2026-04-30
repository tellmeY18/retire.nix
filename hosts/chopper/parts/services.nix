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
      "--accept-dns=false"
    ];
    openFirewall = true;
  };

  ####################
  # Nextcloud        #
  ####################
  services.nextcloud = {
    enable = true;
    hostName = "next.tellmey.tech";

    # Manually increment with every major upgrade.
    package = pkgs.nextcloud32;

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
  services.cloudflared = {
    enable = true;
    tunnels."b0ca1206-1d09-4892-9d69-d3a196877013" = {
      credentialsFile = "/run/secrets/cloudflared-tunnel-credentials";
      default = "http_status:404";
      ingress = {
        "next.tellmey.tech" = {
          service = "http://localhost:80";
        };
        "chat.tellmey.tech" = {
          service = "http://localhost:6167";
        };
        "cal.tellmey.tech" = {
          service = "http://localhost:4000";
        };
        "school.tellmey.tech" = {
          service = "http://localhost:7000";
        };
      };
    };
  };

  ####################
  # ZFS Maintenance  #
  ####################
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };
}
