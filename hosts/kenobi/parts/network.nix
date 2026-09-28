# OCI networking for kenobi.
# - DHCP on the primary interface (enp0s6)
# - Jumbo frames (MTU 9000) preserved for OCI VCN performance
# - Firewall: public-facing ports (SSH, HTTP, HTTPS) + Tailscale
# - Static route for chopper's pod CIDR via Tailscale (host-gw flannel)
#
# Shared k3s node networking lives in profiles/k3s-node-network.nix.
{ config, ... }:
{
  imports = [ ../../../profiles/k3s-node-network.nix ];

  networking = {
    # Cloud VMs use DHCP — no NetworkManager needed.
    useDHCP = true;

    # OCI VCN uses jumbo frames for better throughput.
    interfaces.enp0s6.mtu = 9000;

    firewall = {
      # Public-facing ports (Traefik handles HTTP/HTTPS)
      allowedTCPPorts = [
        22
        80
        443
      ];
      # Tailscale UDP port for WireGuard tunnel + derper STUN (UDP 3478).
      # NOTE: both also require matching OCI VCN security-list ingress rules
      # (cloud firewall) — the NixOS firewall alone is not sufficient on OCI.
      allowedUDPPorts = [
        config.services.tailscale.port
        3478
      ];
    };

    # k3s flannel host-gw: route other nodes' pod CIDRs via their Tailscale IPs.
    localCommands = ''
      ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink 2>/dev/null || true
      ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink 2>/dev/null || true
    '';
  };

  # kenobi-only: tie the route unit's lifecycle to k3s.
  systemd.services.k3s-pod-routes = {
    bindsTo = [ "k3s.service" ];
    # Routes to chopper (10.42.0.0/24) and c3po (10.42.2.0/24).
    serviceConfig.ExecStart =
      ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink"'';
  };

  # Tailscale for cluster connectivity
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
      # Advertise this node's pod CIDR so other nodes can route to our pods
      "--advertise-routes=10.42.1.0/24"
    ];
    openFirewall = true;
  };
}
