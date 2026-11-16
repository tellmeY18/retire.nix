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
    };
  };
}
