# modules/services/cloudflared-dns.nix
#
# Declaratively provisions Cloudflare DNS CNAME records for every
# hostname found in `services.cloudflared.tunnels.<id>.ingress`.
#
# How it works:
#   - At activation, a systemd one-shot runs `cloudflared tunnel route dns`
#     for each (tunnel, hostname) pair.
#   - The command is idempotent: if the record already exists and points
#     to the right tunnel, it's a no-op. If it doesn't exist, it's created.
#   - Hostnames are extracted automatically from the ingress attrset, so
#     the cloudflared config remains the single source of truth.
#
# Requirements:
#   - cloudflared uses the tunnel's `cert.pem` to authenticate with
#     Cloudflare's API for DNS record creation. Generate it with
#     `cloudflared tunnel login` on a workstation, then store the file
#     in sops as a secret.
#   - You must provide `services.cloudflared-dns.certificateFile` pointing
#     to that secret (e.g. `/run/secrets/cloudflare-cert`).

{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.services.cloudflared-dns;

  # Build a list of { tunnelId, hostname } pairs from every tunnel's ingress.
  # We exclude wildcard hostnames (containing "*") because cloudflared can't
  # provision DNS for those — they need to be set up manually.
  pairs = lib.flatten (
    lib.mapAttrsToList
      (
        tunnelId: tunnel:
          map (hostname: { inherit tunnelId hostname; }) (
            lib.filter (h: !(lib.hasInfix "*" h)) (lib.attrNames tunnel.ingress)
          )
      )
      config.services.cloudflared.tunnels
  );

  # cert.pem path inside the unit's credentials directory (set by LoadCredential)
  certPath = "/run/credentials/cloudflared-dns.service/cert.pem";

  # Generate the provisioning script.
  provisionScript = pkgs.writeShellScript "cloudflared-provision-dns" ''
    set -euo pipefail
    export TUNNEL_ORIGIN_CERT="${certPath}"

    ${lib.concatMapStringsSep "\n" (
      { tunnelId, hostname }:
      ''
        echo "[cloudflared-dns] Ensuring CNAME: ${hostname} -> ${tunnelId}"
        ${cfg.package}/bin/cloudflared tunnel route dns \
          --overwrite-dns \
          ${tunnelId} ${hostname} || {
          echo "[cloudflared-dns] WARN: failed to provision ${hostname}" >&2
          # Don't fail activation if a single DNS record can't be created;
          # log and continue so the tunnel itself still starts.
        }
      ''
    ) pairs}

    echo "[cloudflared-dns] DNS provisioning complete."
  '';
in
{
  options.services.cloudflared-dns = {
    enable = lib.mkEnableOption ''
      Automatic DNS CNAME provisioning for cloudflared tunnel ingress hostnames.
      Requires a Cloudflare origin cert (cert.pem) — typically managed via sops.
    '';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cloudflared;
      description = "The cloudflared package to use for DNS provisioning.";
    };

    certificateFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the Cloudflare origin certificate (cert.pem) used to
        authenticate with the Cloudflare API for DNS record creation.

        This is typically a sops-nix secret path, e.g.
        `config.sops.secrets."cloudflare-cert".path`.

        Generate with: cloudflared tunnel login
      '';
      example = "/run/secrets/cloudflare-cert";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate that cloudflared itself is enabled.
    assertions = [
      {
        assertion = config.services.cloudflared.enable;
        message = ''
          services.cloudflared-dns.enable requires services.cloudflared.enable.
        '';
      }
    ];

    systemd.services.cloudflared-dns = {
      description = "Provision Cloudflare DNS records for tunnel ingress";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # systemd LoadCredential places cert.pem at $CREDENTIALS_DIRECTORY/cert.pem
      # (root-readable only), avoiding any plaintext secret on disk.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = [ "cert.pem:${cfg.certificateFile}" ];
        ExecStart = provisionScript;

        # Hardening
        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
