# hosts/chopper/parts/k3s.nix — k3s control plane configuration for chopper.
#
# chopper is the cluster's first control plane node (server-init).
# Tailscale IP: 100.107.213.17
#
# TLS SANs include every address the API server might be reached at:
#   - Node's own Tailscale IP + MagicDNS name
#   - The shared control plane LB endpoint (k3s-cp) managed by the
#     Tailscale operator — this is what kubeconfig uses
#   - Kubernetes internal names
#
# When adding more control plane nodes, they need the SAME shared SANs
# (k3s-cp, k3s-cp.tail477f2f.ts.net) plus their own per-node entries.
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # First server — bootstraps the embedded etcd cluster.
    role = "server-init";
    clusterInit = true;

    # Static Tailscale IP — all k3s traffic binds to the tailnet.
    nodeIP = "100.107.213.17";

    # Join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    extraFlags = [
      # ── Per-node SANs ──
      "--tls-san=chopper"
      "--tls-san=100.107.213.17"
      "--tls-san=chopper.tail477f2f.ts.net"

      # ── Shared control plane SANs ──
      # The Tailscale operator creates a LB device with hostname "k3s-cp".
      # All kubeconfig clients connect via this stable address.
      "--tls-san=k3s-cp"
      "--tls-san=k3s-cp.tail477f2f.ts.net"
    ];
  };
}
