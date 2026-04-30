# modules/services/cloudflared-bootstrap.nix
#
# Auto-creates Cloudflare tunnels by name if they don't already exist.
# Combined with `services.cloudflared` and `services.cloudflared-dns`,
# this makes the entire tunnel lifecycle (creation, ingress routing,
# DNS records) fully declarative — no manual UUID-shuffling required.
#
# How it works:
#   - At activation, a systemd oneshot reads the list of tunnel names
#     declared in `services.cloudflared-bootstrap.tunnels`.
#   - For each name, it queries Cloudflare ("does this tunnel exist?").
#   - If yes: no-op.
#   - If no: creates the tunnel via API, writes the credentials JSON to
#     /var/lib/cloudflared/<name>.json (root-only).
#   - The cloudflared service then reads that file via LoadCredential.
#
# The `cert.pem` (account-level Cloudflare credential) is required, the
# same one used by `services.cloudflared-dns`. See `docs/cloudflare.md`.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.cloudflared-bootstrap;

  # Persistent location for auto-created tunnel credentials.
  # Not in /run/ because we need them to survive reboots — recreating the
  # tunnel on every boot would invalidate the old one in Cloudflare.
  credDir = "/var/lib/cloudflared";

  # cert.pem path inside the unit's credentials directory (set by LoadCredential)
  certPath = "/run/credentials/cloudflared-bootstrap.service/cert.pem";

  bootstrapScript = pkgs.writeShellScript "cloudflared-bootstrap" ''
    set -euo pipefail
    export TUNNEL_ORIGIN_CERT="${certPath}"

    install -d -m 0700 -o root -g root ${credDir}

    ${lib.concatMapStringsSep "\n" (name: ''
      echo "[cloudflared-bootstrap] Ensuring tunnel: ${name}"

      # Check if a tunnel with this name already exists in Cloudflare.
      EXISTING=$(${cfg.package}/bin/cloudflared tunnel list --output json 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r --arg name "${name}" '
            .[] | select(.name == $name and (.deleted_at // "") == "") | .id
          ' || true)

      if [ -n "$EXISTING" ] && [ -f ${credDir}/${name}.json ]; then
        echo "[cloudflared-bootstrap] Tunnel '${name}' (id: $EXISTING) exists, credentials present."
      elif [ -n "$EXISTING" ] && [ ! -f ${credDir}/${name}.json ]; then
        # Tunnel exists in Cloudflare but credentials file is missing locally.
        # We can't recover the credentials — Cloudflare doesn't let you re-download them.
        # The only option is to rotate: delete and recreate.
        echo "[cloudflared-bootstrap] Tunnel '${name}' exists in Cloudflare but credentials are missing locally."
        echo "[cloudflared-bootstrap] Rotating: deleting and recreating tunnel '${name}'."
        ${cfg.package}/bin/cloudflared tunnel delete --force ${name} || true
        ${cfg.package}/bin/cloudflared tunnel create \
          --credentials-file ${credDir}/${name}.json \
          ${name}
      else
        # Tunnel doesn't exist — create it.
        echo "[cloudflared-bootstrap] Creating tunnel '${name}'..."
        ${cfg.package}/bin/cloudflared tunnel create \
          --credentials-file ${credDir}/${name}.json \
          ${name}
      fi

      chmod 600 ${credDir}/${name}.json
      chown root:root ${credDir}/${name}.json
    '') cfg.tunnels}

    echo "[cloudflared-bootstrap] Bootstrap complete."
  '';
in
{
  options.services.cloudflared-bootstrap = {
    enable = lib.mkEnableOption ''
      Automatic Cloudflare tunnel creation. For each name in `tunnels`,
      ensures a tunnel with that name exists in your Cloudflare account
      and writes its credentials file to /var/lib/cloudflared/<name>.json.
    '';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cloudflared;
      description = "The cloudflared package to use.";
    };

    certificateFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the Cloudflare origin certificate (cert.pem) used to
        authenticate with the Cloudflare API for tunnel management.

        Typically a sops-nix secret path, e.g.
        `/run/secrets/cloudflare-cert`.
      '';
      example = "/run/secrets/cloudflare-cert";
    };

    tunnels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of tunnel names to ensure exist. Each name will be passed to
        `cloudflared tunnel create <name>` if it doesn't already exist.
      '';
      example = [ "chopper-main" ];
    };

    credentialsDir = lib.mkOption {
      type = lib.types.path;
      default = credDir;
      readOnly = true;
      description = ''
        Directory where auto-created tunnel credentials are stored.
        Files are named `<tunnel-name>.json`. Reference these from
        `services.cloudflared.tunnels.<name>.credentialsFile`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflared-bootstrap = {
      description = "Bootstrap Cloudflare tunnels (create if missing)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # Run before any cloudflared tunnel service so credentials exist
      # by the time tunnels try to start.
      before = map (name: "cloudflared-tunnel-${name}.service") cfg.tunnels;

      # cert.pem is loaded into a tmpfs credential dir, never written to disk.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root"; # needs to write /var/lib/cloudflared
        LoadCredential = [ "cert.pem:${cfg.certificateFile}" ];
        ExecStart = bootstrapScript;
      };
    };
  };
}
