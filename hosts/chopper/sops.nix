# hosts/chopper/sops.nix — Secret declarations for the chopper host.
# Requires: sops-nix.nixosModules.sops in the host's module list (already done).
{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/chopper/secrets.yaml;

    # The host's age key (derived from SSH host key)
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Fallback key path for sops-nix
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;

    secrets = {
      "tailscale-auth-key" = {
        # Will be available at config.sops.secrets."tailscale-auth-key".path
        # (typically /run/secrets/tailscale-auth-key)
      };
      "nextcloud-admin-pass" = {
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0400";
      };
      "cloudflared-tunnel-credentials" = {
        owner = "cloudflared";
        # mode = "0400";
      };
    };
  };
}
