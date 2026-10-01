# hosts/chopper/sops.nix — Secret declarations for the chopper host.
# Requires: sops-nix.nixosModules.sops in the host's module list (already done).
#
# The host's private age key must exist at the path below.
# Generate it on the host with: age-keygen -o /var/lib/sops-nix/key.txt
# Then add the PUBLIC key to .sops.yaml under &chopper.
{ ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/chopper/secrets.yaml;

    # Age key generated with `age-keygen` — NOT derived from SSH keys.
    # sops-nix reads this at activation to decrypt secrets.
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = false; # We manage key generation manually

    # Do NOT use SSH key derivation
    age.sshKeyPaths = [ ];

    secrets = {
      "tailscale-auth-key" = {
        # Decrypted to /run/secrets/tailscale-auth-key
      };
      # nextcloud-admin-pass removed — Nextcloud is disabled, user doesn't exist.
      "cloudflare-cert" = {
        # Origin cert (cert.pem) for declarative DNS provisioning AND
        # tunnel auto-creation via services.cloudflared-{bootstrap,dns}.
        # Generated with `cloudflared tunnel login` on a workstation, then
        # encrypted into secrets/chopper/secrets.yaml.
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # -----------------------------------------------------------------------
      # k3s cluster secrets
      # -----------------------------------------------------------------------

      # Shared cluster join token — same value used on all nodes.
      # Key in secrets/chopper/secrets.yaml: k3s-token
      # Generate: openssl rand -hex 32
      "k3s-token" = { };

      # Tailscale Kubernetes Operator OAuth credentials — two separate keys.
      # Keys in secrets/chopper/secrets.yaml:
      #   tailscale-operator-client-id
      #   tailscale-operator-client-secret
      # Create the OAuth client at https://login.tailscale.com/admin/settings/oauth
      # Scopes: devices:write, auth_keys:write   Tag: tag:k8s
      "tailscale-operator-client-id" = { };
      "tailscale-operator-client-secret" = { };

      # -----------------------------------------------------------------------
      # Hermes Agent secrets
      # -----------------------------------------------------------------------

      # Single dotenv file consumed by services.hermes-agent.environmentFiles
      # and by the signal-cli-daemon unit's EnvironmentFile. Replaces the
      # seven separate openclaw-* secrets: the upstream Hermes module reads
      # KEY=VALUE env files directly, so the jq-merging wrapper script that
      # OpenClaw needed is gone.
      #
      # Expected keys (see hosts/chopper/parts/hermes.nix):
      #   OPENROUTER_API_KEY    — default model provider
      #   ANTHROPIC_API_KEY     — direct Anthropic
      #   OPENAI_API_KEY        — Whisper/STT and OpenAI models
      #   GITHUB_TOKEN          — GitHub Copilot / Models backend
      #   SIGNAL_ACCOUNT        — bot phone number, E.164
      #   SIGNAL_ALLOWED_USERS  — comma-separated E.164 numbers (NOT a JSON
      #                           array; Hermes differs from OpenClaw here)
      #   SIGNAL_GROUP_ALLOWED_USERS — comma-separated Signal group IDs.
      #                           UNSET MEANS ALL GROUP MESSAGES ARE IGNORED
      #                           (DM-only). This is the Hermes equivalent of
      #                           OpenClaw's groupPolicy = "open". Use `*` for
      #                           every group the account belongs to.
      #   SIGNAL_HOME_CHANNEL   — default delivery target for cron jobs
      #
      # Edit with: sops secrets/chopper/secrets.yaml
      #
      # restartUnits matters here: without it, rotating a provider key
      # re-renders /run/secrets/hermes-env but the running gateway keeps the
      # old value in memory, so the rotation silently does nothing.
      "hermes-env" = {
        owner = "hermes";
        group = "hermes";
        mode = "0400";
        restartUnits = [
          "hermes-agent.service"
          "hermes-backend.service"
          "signal-cli-daemon.service"
        ];
      };

      # Stable session token for the `hermes serve` backend. Without it the
      # backend mints a new token on every start and Hermes Desktop on the
      # Mac cannot re-attach. Raw token on one line, nothing else.
      # Generate: openssl rand -hex 32
      "hermes-dashboard-token" = {
        owner = "hermes";
        group = "hermes";
        mode = "0400";
      };

      # Plaintext of the dashboard basic-auth password. Stored for recall
      # only — the service reads the scrypt hash from config.yaml (set in
      # hosts/chopper/parts/hermes.nix), not this file. Username: vysakh.
      # Used at https://chopper.tail477f2f.ts.net
      "hermes-dashboard-password" = {
        owner = "hermes";
        group = "hermes";
        mode = "0400";
      };

    };
  };
}
