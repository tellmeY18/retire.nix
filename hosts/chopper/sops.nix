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
      # OpenClaw secrets
      # -----------------------------------------------------------------------

      # Gateway authentication token — readable by the openclaw user since the
      # wrapper script reads it at startup to set OPENCLAW_GATEWAY_TOKEN.
      # Key in secrets/chopper/secrets.yaml: openclaw-gateway-token
      "openclaw-gateway-token" = {
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

      # Anthropic API key — read directly by the gateway process from the path
      # set in the ANTHROPIC_API_KEY environment variable.
      "openclaw-anthropic-key" = {
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

      # Signal phone number — read by the gateway wrapper script to set the
      # OPENCLAW_SIGNAL_NUMBER env var for the @openclaw/signal channel.
      "openclaw-signal-number" = {
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

      # OpenAI API key — passed to the gateway as OPENAI_API_KEY.
      "openclaw-openai-key" = {
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

      # NVIDIA AI API key — used with the OpenAI-compatible endpoint at
      # https://integrate.api.nvidia.com/v1 for the NVIDIA model backend.
      "openclaw-nvidia-key" = {
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

      # Signal DM allowlist — JSON array of phone numbers allowed to DM the bot
      # when dmPolicy = "allowlist". Read by the wrapper script and injected into
      # the merged config via jq. Re-encrypt with your age key when adding numbers.
      "openclaw-signal-allowlist" = {
        owner = "openclaw";
        group = "openclaw";
        mode = "0400";
      };

    };
  };
}
