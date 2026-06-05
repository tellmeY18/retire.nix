# hosts/chopper/parts/k3s.nix — k3s control plane configuration for chopper.
#
# chopper is a control-plane + etcd server. It originally bootstrapped the
# cluster (server-init / --cluster-init), but that role is only meaningful at
# first bootstrap. After a 2026-06-05 incident wedged chopper's etcd member,
# it was rebuilt as a normal JOINING server (role = server): --cluster-init is
# removed so a wipe-and-rejoin can never accidentally bootstrap a split-brain
# cluster. Any server can perform `k3s server --cluster-reset` for DR, so no
# node needs to remain server-init.
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

    # Server — joins the existing etcd cluster (no longer the bootstrap node).
    role = "server";

    # Join via kenobi's apiserver (the reliable, public node — it serves the
    # authoritative etcd member list for bootstrap). Joining via the flaky c3po
    # handed the rejoining member a bad initial-cluster ("failed to find remote
    # peer") and the etcd member never synced. Only used at join time; once
    # joined, chopper operates from its local etcd.
    serverAddr = "https://100.73.101.89:6443";

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
