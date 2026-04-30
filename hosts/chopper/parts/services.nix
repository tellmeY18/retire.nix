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
  # Tunnels are auto-created by services.cloudflared-bootstrap below.
  # We reference them by NAME (not UUID) so the config has a stable SSOT.
  # The credentials file is auto-written by the bootstrap module.
  services.cloudflared = {
    enable = true;
    tunnels.chopper-main = {
      credentialsFile = "/var/lib/cloudflared/chopper-main.json";
      default = "http_status:404";
      ingress = {
        "next.tellmey.fyi" = {
          service = "http://localhost:80";
        };
        "chat.tellmey.fyi" = {
          service = "http://localhost:6167";
        };
        "cal.tellmey.fyi" = {
          service = "http://localhost:4000";
        };
        "school.tellmey.fyi" = {
          service = "http://localhost:7000";
        };
      };
    };
  };

  # Auto-create tunnels in Cloudflare on activation if they don't exist.
  # Writes credentials to /var/lib/cloudflared/<name>.json.
  services.cloudflared-bootstrap = {
    enable = true;
    certificateFile = "/run/secrets/cloudflare-cert";
    tunnels = [ "chopper-main" ];
  };

  # Declarative DNS provisioning — auto-creates Cloudflare CNAMEs for every
  # hostname declared in services.cloudflared.tunnels.<name>.ingress above.
  services.cloudflared-dns = {
    enable = true;
    certificateFile = "/run/secrets/cloudflare-cert";
  };

  ####################
  # ZFS Maintenance  #
  ####################
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };
}
