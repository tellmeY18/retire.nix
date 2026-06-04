# OCI networking for kenobi.
# - DHCP on the primary interface (enp0s6)
# - Jumbo frames (MTU 9000) preserved for OCI VCN performance
# - Firewall: public-facing ports (SSH, HTTP, HTTPS) + Tailscale
# - Static route for chopper's pod CIDR via Tailscale (host-gw flannel)
{ config, pkgs, ... }:
{
  networking = {
    # Cloud VMs use DHCP — no NetworkManager needed.
    useDHCP = true;

    # OCI VCN uses jumbo frames for better throughput.
    interfaces.enp0s6.mtu = 9000;

    firewall = {
      enable = true;
      # Public-facing ports (Traefik handles HTTP/HTTPS)
      allowedTCPPorts = [
        22
        80
        443
      ];
      # Tailscale UDP port for WireGuard tunnel
      allowedUDPPorts = [ config.services.tailscale.port ];
      # Trust the tailnet + pod bridge interfaces
      trustedInterfaces = [
        "tailscale0"
        "cni0"
      ];

      # Allow forwarding between tailscale0 and pod networks (cni0).
      # MUST use -I (insert at top) because kube-router's FORWARD rules
      # run first and drop cross-node pod traffic that arrives via tailscale0.
      extraCommands = ''
        iptables -I FORWARD 1 -i tailscale0 -d 10.42.0.0/16 -j ACCEPT
        iptables -I FORWARD 1 -s 10.42.0.0/16 -o tailscale0 -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D FORWARD -i tailscale0 -d 10.42.0.0/16 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -s 10.42.0.0/16 -o tailscale0 -j ACCEPT 2>/dev/null || true
      '';
    };

    # k3s flannel host-gw: route other nodes' pod CIDRs via their Tailscale IPs.
    localCommands = ''
      ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink 2>/dev/null || true
      ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink 2>/dev/null || true
    '';
  };

  # Ensure pod CIDR route is added AFTER tailscale is online.
  # localCommands runs too early (before tailscale0 exists).
  systemd.services.k3s-pod-routes = {
    description = "Add cross-node pod CIDR routes via Tailscale";
    after = [
      "tailscaled.service"
      "k3s.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    # iproute2 must be on PATH — the ExecStartPre/ExecStart use `ip`. Without
    # this the `until ip link show ... UP` loop runs `ip: command not found`
    # forever (stderr swallowed), wedging switch-to-configuration and every
    # subsequent deploy.
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = ''/bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done"'';
      ExecStart = ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink"'';
    };
  };

  # Tailscale for cluster connectivity
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns=false"
      # Advertise this node's pod CIDR so other nodes can route to our pods
      "--advertise-routes=10.42.1.0/24"
    ];
    openFirewall = true;
  };
}
