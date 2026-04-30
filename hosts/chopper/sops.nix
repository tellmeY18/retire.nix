# hosts/chopper/sops.nix — Secret declarations for the chopper host.
# Requires: sops-nix.nixosModules.sops in the host's module list (already done).
#
# The host's private age key must exist at the path below.
# Generate it on the host with: age-keygen -o /var/lib/sops-nix/key.txt
# Then add the PUBLIC key to .sops.yaml under &chopper.
{ config, ... }:
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
      "nextcloud-admin-pass" = {
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0400";
      };
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
      # Encrypted file: secrets/chopper/k3s-token
      # Generate token: openssl rand -hex 32
      "k3s-token" = {
        sopsFile = ../../secrets/chopper/k3s-token;
        # No format — sops treats the whole file as the secret value.
        format = "binary";
      };

      # Tailscale Kubernetes Operator OAuth credentials.
      # Encrypted file: secrets/chopper/tailscale-operator-oauth
      # Used by modules/services/k3s-bootstrap-manifests.nix to render
      # the operator-oauth Secret manifest at boot (via systemd oneshot).
      # NEVER passes through the Nix store — decrypted to /run/secrets/ only.
      "tailscale-operator-oauth" = {
        sopsFile = ../../secrets/chopper/tailscale-operator-oauth;
        format = "binary";
      };
    };
  };
}
