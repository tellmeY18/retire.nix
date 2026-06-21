# hosts/r2d2/sops.nix — Secret declarations for the r2d2 host.
#
# The host's private age key must exist at the path below.
# Generate on the host with: age-keygen -o /var/lib/sops-nix/key.txt
# Then add the PUBLIC key to .sops.yaml under &r2d2.
{ ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/r2d2/secrets.yaml;

    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = false;
    age.sshKeyPaths = [ ];

    secrets = {
      # Tailscale pre-auth key for joining the tailnet on boot.
      "tailscale-auth-key" = { };

      # Shared k3s cluster join token — same value as chopper's.
      "k3s-token" = { };
    };
  };
}
