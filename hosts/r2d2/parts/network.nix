# hosts/r2d2/parts/network.nix — Proxmox VM networking
# - DHCP on the primary interface (virtio NIC on vmbr0)
# - Firewall: SSH + Tailscale
# - Static routes for other nodes' pod CIDRs via Tailscale (host-gw flannel)
{ config, pkgs, ... }:
{
  # systemd-resolved for split-DNS — Tailscale configures the tailscale0
  # link to route .ts.net queries through 100.100.100.100 (MagicDNS),
  # while everything else goes through upstream DNS.
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ "8.8.8.8" "1.1.1.1" ];
  };

  networking = {
    # Proxmox DHCP
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [
        "tailscale0"
        "cni0"
      ];

      # Allow forwarding between tailscale0 and pod networks.
      extraCommands = ''
        iptables -I FORWARD 1 -i tailscale0 -d 10.42.0.0/16 -j ACCEPT
        iptables -I FORWARD 1 -s 10.42.0.0/16 -o tailscale0 -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D FORWARD -i tailscale0 -d 10.42.0.0/16 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -s 10.42.0.0/16 -o tailscale0 -j ACCEPT 2>/dev/null || true
      '';
    };
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

  # Ensure pod CIDR route is added AFTER tailscale is online.
  systemd.services.k3s-pod-routes = {
    description = "Add cross-node pod CIDR routes via Tailscale";
    after = [
      "tailscaled.service"
      "k3s.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = ''/bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done"'';
      # Routes to chopper (10.42.0.0/24), kenobi (10.42.1.0/24), c3po (10.42.2.0/24)
      ExecStart = ''
        /bin/sh -c " \
          ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; \
          ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink; \
          ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink \
        "
      '';
    };
  };
}
