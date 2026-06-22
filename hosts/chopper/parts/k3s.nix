# hosts/chopper/parts/k3s.nix — k3s agent (worker) configuration for chopper.
#
# Demoted from server to agent on 2026-06-22 after the etcd defrag storm.
# kenobi is now the sole control plane; chopper is a worker node.
#
# Tailscale IP: 100.107.213.17
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # Agent — worker node, no etcd or control plane components.
    role = "agent";

    # Join via kenobi's apiserver (the sole CP).
    serverAddr = "https://100.73.101.89:6443";

    # Static Tailscale IP — all k3s traffic binds to the tailnet.
    nodeIP = "100.107.213.17";

    # Join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;
  };
}
