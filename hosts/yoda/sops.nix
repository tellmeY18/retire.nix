# hosts/yoda/sops.nix — Secret declarations for the yoda host (phase 2).
#
# The host's private age key must exist at the path below.
# It was generated on the operator's Mac and copied to the host:
#   age-keygen -o key.txt && scp key.txt root@yoda:/var/lib/sops-nix/key.txt
# The PUBLIC key is registered in .sops.yaml under &yoda.
{ ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/yoda/secrets.yaml;

    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = false;
    age.sshKeyPaths = [ ];

    secrets = {
      # Tailscale pre-auth key for joining the tailnet on boot.
      "tailscale-auth-key" = { };

      # Shared k3s cluster join token — same value as the other nodes'.
      "k3s-token" = { };
    };
  };
}
