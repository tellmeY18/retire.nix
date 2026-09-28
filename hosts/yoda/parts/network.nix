# hosts/yoda/parts/network.nix — OCI networking for yoda (phase 2).
#
# yoda is an x86_64 OCI KVM VM joining the tailnet as a k3s compute node.
#   - DHCP on the primary interface (ens3)
#   - Tailscale for all cluster traffic (k3s binds to tailscale0)
#   - host-gw flannel: explicit onlink routes to each peer's pod CIDR
#
# MTU note: unlike kenobi, this instance's VCN negotiated MTU 1500 on ens3
# (jumbo frames are NOT active end-to-end here), so we do NOT force 9000 —
# doing so would create an MTU blackhole. Tailscale sets its own tunnel MTU.
#
# Cluster peers (Tailscale IP → pod CIDR):
#   chopper  100.107.213.17 → 10.42.0.0/24
#   kenobi   100.73.101.89  → 10.42.1.0/24   (sole control plane)
#   c3po     100.109.132.76 → 10.42.2.0/24
#   yoda     (this node)    → 10.42.3.0/24
#
# Shared k3s node networking lives in profiles/k3s-node-network.nix.
{ config, ... }:
{
  imports = [
    ../../../profiles/k3s-node-network.nix
    ../../../profiles/tailscale-online.nix
  ];

  networking = {
    # Cloud VMs use DHCP — no NetworkManager needed.
    useDHCP = true;
    # Compute node — no public HTTP/HTTPS. SSH only on the public iface.
    firewall.allowedTCPPorts = [ 22 ];
  };

  # Tailscale — accept routes from other nodes + advertise our pod CIDR.
  services.tailscale = {
    enable = true;
    # openFirewall opens the WireGuard UDP port — required for direct peer
    # connections. Without it, Tailscale falls back to DERP relay and
    # flannel host-gw can't initialise.
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
      # Advertise this node's pod CIDR so peers can route to our pods.
      "--advertise-routes=10.42.3.0/24"
    ];
  };

  # yoda gets podCIDR 10.42.3.0/24; it needs routes to every OTHER node's
  # pod CIDR via that node's Tailscale IP (host-gw).
  systemd.services.k3s-pod-routes.serviceConfig.ExecStart =
    ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink; ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink"'';
}
