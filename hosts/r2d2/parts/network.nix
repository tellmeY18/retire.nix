# hosts/r2d2/parts/network.nix — Proxmox VM networking
# - DHCP on the primary interface (virtio NIC on vmbr0)
# - Firewall: SSH + Tailscale
# - Static routes for other nodes' pod CIDRs via Tailscale (host-gw flannel)
#
# Shared k3s node networking lives in profiles/k3s-node-network.nix.
{ config, ... }:
{
  imports = [ ../../../profiles/k3s-node-network.nix ];

  networking = {
    # Proxmox DHCP
    useDHCP = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  # Tailscale — accept routes, advertise pod CIDR (10.42.3.0/24)
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
      "--advertise-routes=10.42.3.0/24"
    ];
  };

  # Routes to chopper (10.42.0.0/24), kenobi (10.42.1.0/24), c3po (10.42.2.0/24)
  systemd.services.k3s-pod-routes.serviceConfig.ExecStart = ''
    /bin/sh -c " \
      ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; \
      ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink; \
      ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink \
    "
  '';
}
