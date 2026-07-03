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

  # OpenClaw uses LLMs to process untrusted content — upstream marks it
  # insecure due to prompt-injection risk. We accept this intentionally.
  nixpkgs.config.permittedInsecurePackages = [ "openclaw-2026.6.5" ];

  ####################
  # OpenClaw Gateway #
  ####################
  services.openclaw-gateway = {
    enable = true;
    port = 18789;

    # Bind to all interfaces for LAN access
    execStart = "${config.services.openclaw-gateway.package}/bin/openclaw gateway --bind all --port ${toString config.services.openclaw-gateway.port}";

    # Basic config — add tokens via sops secrets below
    config = {
      gateway = {
        mode = "local";
        auth.token = { source = "env"; provider = "default"; id = "OPENCLAW_GATEWAY_TOKEN"; };
      };
    };

    environment = {
      # Point these to sops-decrypted runtime paths when secrets are created:
      # OPENCLAW_GATEWAY_TOKEN = config.sops.secrets.openclaw-gateway-token.path;
      # ANTHROPIC_API_KEY       = config.sops.secrets.openclaw-anthropic-key.path;
      # TELEGRAM_BOT_TOKEN      = config.sops.secrets.openclaw-telegram-token.path;
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
