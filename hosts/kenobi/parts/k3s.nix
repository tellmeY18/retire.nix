# hosts/kenobi/parts/k3s.nix — k3s server (HA) configuration for kenobi.
#
# kenobi is being promoted from agent to server to form a 2-node HA
# control plane with chopper. As an OCI cloud VM, kenobi has better
# uptime guarantees than chopper (a laptop subject to power outages).
#
# Tailscale IP: 100.73.101.89
#
# WARNING: 2-node etcd has NO fault tolerance (need 2/2 for quorum).
# Promote c3po to server as well for true HA (3 voters, tolerates 1 failure).
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # Server — joins existing etcd cluster (chopper is server-init).
    role = "server";

    # Join the existing cluster via chopper's apiserver.
    serverAddr = "https://100.107.213.17:6443";

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
