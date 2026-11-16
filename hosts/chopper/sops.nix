# hosts/chopper/sops.nix — Secret declarations for the chopper host.
# Requires: sops-nix.nixosModules.sops in the host's module list (already done).
#
# The host's private age key must exist at the path below.
# Generate it on the host with: age-keygen -o /var/lib/sops-nix/key.txt
# Then add the PUBLIC key to .sops.yaml under &chopper.
{ lib, ... }:
let
  # Every SSH key (Chopper's satan@chopper + all keys from the retired Mac)
  # and the SSH config, from secrets/chopper/ssh.yaml into satan's ~/.ssh.
  sshFiles = [
    "config"
    "id_ed25519" # satan@chopper — the fleet deploy key
    "id_ed25519_mac" # the Mac's old ~/.ssh/id_ed25519
    "id_rsa"
    "10bedicu_id_rsa"
    "10bednix-key"
    "digit-demo.pem"
    "google_compute_engine"
    "id_knot_ohc"
    "key_khushi"
    "id_rsa_temp"
    "temp"
    "workspace"
  ];
  pubs = map (n: "${n}.pub") (lib.subtractLists [ "config" "10bednix-key" "digit-demo.pem" ] sshFiles);
  sshSecret = mode: n: lib.nameValuePair "ssh/${n}" {
    sopsFile = ../../secrets/chopper/ssh.yaml;
    path = "/home/satan/.ssh/${n}";
    owner = "satan";
    group = "users";
    inherit mode;
  };
in
{
  sops = {
    defaultSopsFile = ../../secrets/chopper/secrets.yaml;

    # Age key generated with `age-keygen` — NOT derived from SSH keys.
    # sops-nix reads this at activation to decrypt secrets.
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = false; # We manage key generation manually

    # Do NOT use SSH key derivation
    age.sshKeyPaths = [ ];

    secrets = lib.listToAttrs (map (sshSecret "0600") sshFiles ++ map (sshSecret "0644") pubs) // {
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
    };
  };
}
