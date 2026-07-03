# hosts/yoda/parts/k3s.nix — k3s agent (worker) configuration for yoda.
#
# yoda is a COMPUTE node: it joins kenobi's control plane as a plain agent and
# runs stateless workloads only (no etcd, no PVCs — see the compute-node
# profile imported in configuration.nix).
#
# Two-stage bring-up:
#   Stage 2a — tailscaleIP = "" below → k3s stays DISABLED. Deploy brings up
#              Tailscale + sops so the node joins the tailnet and is assigned
#              a stable 100.x.y.z address.
#   Stage 2b — set tailscaleIP to that address → k3s agent is enabled and
#              binds --node-ip/--flannel-iface to the tailnet.
#
# Cluster control plane: kenobi @ 100.73.101.89 (sole server-init).
{ config, lib, ... }:
let
  # yoda's static Tailscale IP. Populated after the node first joins the
  # tailnet (stage 2a). Leave "" to keep k3s off during bring-up.
  tailscaleIP = "";
in
{
  services.k3s-cluster = lib.mkIf (tailscaleIP != "") {
    enable = true;

    # Agent — worker node, no etcd or control plane components.
    role = "agent";

    # Join via kenobi's apiserver (the sole control plane).
    serverAddr = "https://100.73.101.89:6443";

    # Same shared join token — sops-nix decrypts at activation.
    tokenFile = config.sops.secrets.k3s-token.path;

    # Tailscale IP — binds flannel/kubelet to the tailnet.
    nodeIP = tailscaleIP;
  };
}
