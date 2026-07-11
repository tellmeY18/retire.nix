# hosts/c3po/parts/k3s.nix — k3s agent (worker) configuration for c3po.
#
# Demoted from server to agent on 2026-06-22 after the etcd defrag storm.
# kenobi is now the sole control plane; c3po is a worker node.
#
# Tailscale IP: 100.109.132.76
{ config, ... }:
{
  imports = [ ../../../modules/services/k3s.nix ];

  services.k3s-cluster = {
    enable = true;

    # Agent — worker node, no etcd or control plane components.
    role = "agent";

    # Join via kenobi's apiserver (the sole CP).
    serverAddr = "https://100.73.101.89:6443";

    # Same join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # Tailscale IP — binds flannel to the tailnet.
    nodeIP = "100.109.132.76";

    extraFlags = [
      "--node-label=node-role.glug.infra/compute=true"
    ];
  };
}
