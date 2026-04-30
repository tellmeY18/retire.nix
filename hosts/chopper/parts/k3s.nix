# hosts/chopper/parts/k3s.nix — k3s cluster configuration for chopper.
#
# chopper is the FIRST (and currently only) k3s server node.
# Role: server-init — bootstraps the embedded-etcd cluster.
#
# Tailscale IP: 100.107.213.17 (static; matches deploy.host in metadata.nix).
# When a second node is added it will join via serverAddr = "https://chopper:6443"
# (or the Tailscale FQDN equivalent).
#
# Secrets consumed here (both declared in hosts/chopper/sops.nix):
#   sops.secrets.k3s-token               → tokenFile
#   sops.secrets.tailscale-operator-oauth → companion bootstrap-manifests module
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # First and only server — bootstraps the etcd cluster.
    role = "server-init";
    clusterInit = true;

    # Static Tailscale IP so all k3s traffic (apiserver, etcd, flannel)
    # binds to the tailnet interface rather than the physical NIC.
    # This IP is stable for this device on the tailnet.
    nodeIP = "100.107.213.17";

    # Join token — sops-nix decrypts secrets/chopper/k3s-token at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # TLS SAN: include the Tailscale FQDN so the kubeconfig `server` URL
    # works from any tailnet member without certificate errors.
    # Replace <tailnet> with your actual tailnet name (e.g. "tail1234.ts.net").
    extraFlags = [
      "--tls-san=chopper"
      # "--tls-san=chopper.<tailnet>.ts.net"   # uncomment once tailnet name is known
    ];
  };
}
