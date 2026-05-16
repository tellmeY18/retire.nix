# hosts/kenobi/parts/k3s.nix — k3s agent configuration for kenobi.
#
# kenobi is a compute-only agent node (OCI aarch64 VM).
# Joins the cluster via the shared control plane endpoint (k3s-cp)
# managed by the Tailscale operator. This ensures kenobi can reach
# a healthy control plane node even if individual servers go down.
#
# Tailscale IP: 100.73.101.89
{ config, ... }:
{
  services.k3s-cluster = {
    enable = true;

    # Worker-only — no etcd, no apiserver.
    role = "agent";

    # Connect via the stable Tailscale LB endpoint.
    # k3s-cp.tail477f2f.ts.net resolves to whichever control plane
    # node is healthy. Falls back to direct IP if MagicDNS is off.
    # NOTE: on first boot before the LB service exists, this will
    # fail to connect. Bootstrap with the direct IP first, then
    # switch to the LB endpoint once it's up.
    serverAddr = "https://100.107.213.17:6443";

    # Same join token as chopper — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # Tailscale IP — binds k3s agent traffic to the tailnet.
    nodeIP = "100.73.101.89";

    extraFlags = [
      # Agents don't need --tls-san (they don't serve the API).
    ];
  };
}
