# hosts/c3po/parts/network.nix — Networking for c3po (k3s agent + Tailscale)
{ config, ... }:
{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [
        "tailscale0"
        "cni0"
      ];

      # Allow forwarding between tailscale0 and pod networks.
      # Required for host-gw flannel cross-node pod traffic.
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

  # Tailscale — accept routes from other nodes + advertise our pod CIDR
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns=false"
      "--advertise-routes=10.42.2.0/24"
    ];
  };

  # Pod CIDR route for other nodes — added after tailscale is online.
  # c3po will get podCIDR 10.42.2.0/24 from the server.
  # Routes to chopper (10.42.0.0/24) and kenobi (10.42.1.0/24):
  systemd.services.k3s-pod-routes = {
    description = "Add cross-node pod CIDR routes via Tailscale";
    after = [
      "tailscaled.service"
      "k3s.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = ''/bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done"'';
      ExecStart = ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink"'';
    };
  };
}
