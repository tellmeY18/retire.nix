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
      "cloudflared-tunnel-credentials" = {
        # cloudflared runs as a DynamicUser via systemd, so there's no
        # static `cloudflared` user on the system. Keep the secret owned
        # by root; systemd makes it accessible to the service.
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
