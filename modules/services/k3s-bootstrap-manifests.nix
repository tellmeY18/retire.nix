# modules/services/k3s-bootstrap-manifests.nix
#
# Companion module to modules/services/k3s.nix.
#
# Handles the Tailscale Kubernetes Operator OAuth credentials — the one
# bootstrap secret that must exist in the cluster before the operator can
# authenticate with Tailscale, but which must NEVER pass through the Nix
# store (the store is world-readable at /nix/store/...).
#
# Mechanism:
#   1. sops-nix decrypts secrets/chopper/tailscale-operator-oauth →
#      /run/secrets/tailscale-operator-oauth at boot (tmpfs, root-only).
#   2. The `k3s-tailscale-oauth-secret` systemd oneshot reads that file,
#      substitutes the values, and writes a Kubernetes Secret manifest to
#      /var/lib/rancher/k3s/server/manifests/tailscale-operator-secret.yaml
#      with mode 0600.
#   3. k3s's built-in manifest watcher picks it up and applies it to the
#      cluster, creating (or updating) the `operator-oauth` Secret in the
#      `tailscale` namespace.
#   4. The Tailscale operator pod reads that Secret to obtain its OAuth
#      client ID and secret, then authenticates with Tailscale.
#
# The secret file format expected at /run/secrets/tailscale-operator-oauth:
#   TAILSCALE_OPERATOR_CLIENT_ID=tskey-client-...
#   TAILSCALE_OPERATOR_CLIENT_SECRET=tskey-...
#
# Corresponding sops declaration in the host config:
#   sops.secrets.tailscale-operator-oauth = {
#     sopsFile = ../../secrets/chopper/tailscale-operator-oauth;
#     # No owner override — root reads it, consistent with how the oneshot runs.
#   };
#
# This module is intentionally separate from k3s.nix so that it can be
# conditionally imported only on nodes that are k3s servers (agents do not
# serve manifests). Import both modules in the host's imports list:
#   ../../modules/services/k3s.nix
#   ../../modules/services/k3s-bootstrap-manifests.nix
#
# Guard: this module is a no-op unless services.k3s-cluster.enable = true,
# so it is safe to import unconditionally in a shared host profile.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

  # Path where k3s server picks up auto-applied manifests on every boot.
  manifestDir = "/var/lib/rancher/k3s/server/manifests";

  # Destination manifest file — written by the oneshot, applied by k3s.
  oauthManifest = "${manifestDir}/tailscale-operator-secret.yaml";

  # The script is kept out-of-line for readability and so that the store path
  # (which contains the script text) never contains the secret values — those
  # are sourced at runtime from /run/secrets/.
  oauthScript = pkgs.writeShellScript "write-tailscale-oauth-secret" ''
    set -euo pipefail

    SECRET_FILE="/run/secrets/tailscale-operator-oauth"

    if [ ! -f "$SECRET_FILE" ]; then
      echo "ERROR: $SECRET_FILE does not exist — sops-nix may not have run yet." >&2
      exit 1
    fi

    # Source the env-var file. Expected format (no export keyword required):
    #   TAILSCALE_OPERATOR_CLIENT_ID=tskey-client-...
    #   TAILSCALE_OPERATOR_CLIENT_SECRET=tskey-...
    # shellcheck disable=SC1090
    source "$SECRET_FILE"

    if [ -z "''${TAILSCALE_OPERATOR_CLIENT_ID:-}" ] || \
       [ -z "''${TAILSCALE_OPERATOR_CLIENT_SECRET:-}" ]; then
      echo "ERROR: TAILSCALE_OPERATOR_CLIENT_ID or TAILSCALE_OPERATOR_CLIENT_SECRET" \
           "is empty after sourcing $SECRET_FILE" >&2
      exit 1
    fi

    mkdir -p "${manifestDir}"

    # Write the Kubernetes Secret manifest. Using printf rather than heredoc
    # avoids any risk of the shell expanding characters inside the values.
    printf '%s\n' \
      'apiVersion: v1' \
      'kind: Secret' \
      'metadata:' \
      '  name: operator-oauth' \
      '  namespace: tailscale' \
      'type: Opaque' \
      'stringData:' \
      "  client_id: \"$TAILSCALE_OPERATOR_CLIENT_ID\"" \
      "  client_secret: \"$TAILSCALE_OPERATOR_CLIENT_SECRET\"" \
      > "${oauthManifest}"

    # 0600: only root (k3s runs as root) may read this file.
    chmod 0600 "${oauthManifest}"

    echo "Tailscale operator OAuth Secret manifest written to ${oauthManifest}"
  '';

in
{
  config = mkIf config.services.k3s-cluster.enable {

    # -------------------------------------------------------------------------
    # sops-nix secret declaration
    #
    # Tells sops-nix to decrypt secrets/chopper/tailscale-operator-oauth and
    # place the plaintext at /run/secrets/tailscale-operator-oauth (tmpfs,
    # survives only until next boot — never persisted to disk).
    #
    # The corresponding encrypted file must exist at:
    #   secrets/chopper/tailscale-operator-oauth
    # and be encrypted with the host's age key (see .sops.yaml creation rules).
    #
    # In the host config, declare the sopsFile path:
    #   sops.secrets.tailscale-operator-oauth = {
    #     sopsFile = ../../secrets/chopper/tailscale-operator-oauth;
    #   };
    # -------------------------------------------------------------------------
    sops.secrets.tailscale-operator-oauth = {
      # sopsFile is expected to be overridden per-host.
      # Default restateVersion is null; sops-nix will error if sopsFile is
      # not set, which is the correct behaviour — fail loudly rather than
      # silently skip the credential.
      restartUnits = [ "k3s-tailscale-oauth-secret.service" ];
    };

    # -------------------------------------------------------------------------
    # Systemd oneshot: write the Tailscale operator OAuth Secret manifest
    #
    # Runs before k3s so the manifest is in place when k3s's manifest watcher
    # first scans the directory. Also runs when sops-nix rotates the secret
    # (via restartUnits above) so the manifest stays current without a full
    # nixos-rebuild.
    # -------------------------------------------------------------------------
    systemd.services.k3s-tailscale-oauth-secret = {
      description = "Write Tailscale operator OAuth Secret manifest for k3s";

      # Must complete before k3s starts so the manifest is present during the
      # initial manifest-watcher scan.
      wantedBy = [ "k3s.service" ];
      before = [ "k3s.service" ];

      # The sops-nix activation service must have run first so that
      # /run/secrets/tailscale-operator-oauth exists.
      after = [
        "sops-nix.service"
        "network-online.target"
      ];
      requires = [ "sops-nix.service" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        # Remain in the "started" state after the oneshot exits so that
        # systemd's dependency graph doesn't re-trigger it unnecessarily.
        RemainAfterExit = true;
        ExecStart = oauthScript;

        # Harden the unit — it only needs to write one file to a specific path.
        User = "root";
        Group = "root";

        # Prevent the script text (in the Nix store) from being confused with
        # the secret values — belt-and-suspenders.
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          manifestDir
          "/run/secrets"
        ];
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

  };
}
