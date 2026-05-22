# hosts/c3po/sops.nix — sops-nix secrets for c3po
{ ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/c3po/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      "tailscale-auth-key" = { };
      "k3s-token" = { };
    };
  };
}
