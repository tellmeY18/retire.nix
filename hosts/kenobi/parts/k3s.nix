# hosts/kenobi/parts/k3s.nix — k3s single control plane for kenobi.
#
# kenobi is the sole control plane node with embedded etcd.
# c3po and chopper are agents (workers).
#
# After a 2026-06-22 etcd defrag storm that took down the 3-node HA
# cluster, the architecture was simplified to single-CP to eliminate
# etcd quorum/snapshot issues on slow hardware.
#
# Tailscale IP: 100.73.101.89
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # Single control plane — owns the etcd cluster.
    role = "server-init";

    # No serverAddr — this IS the server.

    # Same join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # Tailscale IP — binds apiserver, etcd, and flannel to the tailnet.
    nodeIP = "100.73.101.89";

    extraFlags = [
      # ── Per-node SANs ──
      "--tls-san=kenobi"
      "--tls-san=100.73.101.89"
      "--tls-san=kenobi.tail477f2f.ts.net"

      # ── Shared control plane SANs ──
      # Same as chopper — all servers must serve the same shared endpoint.
      "--tls-san=k3s-cp"
      "--tls-san=k3s-cp.tail477f2f.ts.net"

      # ── etcd maintenance ──
      # Auto-compact every hour to prevent unbounded DB growth.
      # Without this, the DB grew from 75MB to 125MB in 30 minutes
      # from MVCC history accumulation (caused the 2026-06-22 defrag storm).
      "--etcd-arg=auto-compaction-mode=periodic"
      "--etcd-arg=auto-compaction-retention=1h"
    ];
  };

  # One-time cleanup: remove stale VXLAN/agent state from when kenobi
  # was an agent using vxlan backend.
  systemd.services.k3s.preStart = ''
    if ip link show flannel.1 &>/dev/null; then
      echo "Removing stale flannel.1 VXLAN device..."
      ip link delete flannel.1 || true
    fi
    if [ -f /var/lib/rancher/k3s/agent/flannel/subnet.env ]; then
      echo "Wiping stale flannel state..."
      rm -f /var/lib/rancher/k3s/agent/flannel/subnet.env
    fi
  '';
}
