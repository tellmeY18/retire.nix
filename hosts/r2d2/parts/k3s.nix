# hosts/r2d2/parts/k3s.nix — k3s agent (compute node) configuration.
#
# r2d2 is a compute-only k3s agent. It joins the cluster via chopper's
# apiserver. No etcd, no storage — pure CPU/RAM for stateless workloads.
#
# Tailscale IP: 100.82.170.61
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # Agent — joins the existing cluster as a worker.
    role = "agent";

    # Join via chopper's apiserver (server-init).
    serverAddr = "https://100.107.213.17:6443";

    # Same join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # Tailscale IP — binds flannel to the tailnet.
    nodeIP = "100.82.170.61";
  };
}
