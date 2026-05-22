# hosts/c3po/parts/k3s.nix — k3s server (HA) configuration for c3po.
#
# c3po is the third control plane node, completing the 3-node HA etcd
# quorum. With 3 voters, the cluster tolerates 1 node failure.
#
# Tailscale IP: 100.109.132.76
{ config, ... }:
{
  imports = [ ../../../modules/services/k3s.nix ];

  services.k3s-cluster = {
    enable = true;

    # Server — joins existing etcd cluster.
    role = "server";

    # Join via chopper's apiserver.
    serverAddr = "https://100.107.213.17:6443";

    # Same join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # Tailscale IP — binds apiserver, etcd, and flannel to the tailnet.
    nodeIP = "100.109.132.76";

    extraFlags = [
      # ── Per-node SANs ──
      "--tls-san=c3po"
      "--tls-san=100.109.132.76"
      "--tls-san=c3po.tail477f2f.ts.net"

      # ── Shared control plane SANs ──
      "--tls-san=k3s-cp"
      "--tls-san=k3s-cp.tail477f2f.ts.net"
    ];
  };
}
