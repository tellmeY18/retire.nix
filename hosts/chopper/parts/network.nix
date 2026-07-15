{ config, pkgs, ... }:
{
  # systemd-resolved for split-DNS — Tailscale configures the tailscale0
  # link to route .ts.net queries through 100.100.100.100 (MagicDNS),
  # while everything else goes through upstream DNS.
  services.resolved = {
    enable = true;
    # Fallback DNS if upstream is unavailable.
    settings.Resolve.FallbackDNS = [ "8.8.8.8" "1.1.1.1" ];
  };

  networking = {
    firewall = {
      enable = true;
      allowedUDPPorts = [
        config.services.tailscale.port
        5353 # mDNS — needed for Android TV device discovery (zeroconf)
      ];
      trustedInterfaces = [
        "tailscale0"
        "cni0"
      ];
      # OpenClaw gateway is exposed via Tailscale Serve (port 443, HTTPS);
      # all legacy web services (Nextcloud, conduwuit, care) bind to
      # localhost and are exposed via Cloudflare Tunnel.
      allowedTCPPorts = [
        22
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
      ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink 2>/dev/null || true
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
    # iproute2 must be on PATH — ExecStartPre/ExecStart use `ip`. Without it
    # the `until ip link show ... UP` loop runs `ip: command not found`
    # forever, wedging switch-to-configuration and every subsequent deploy.
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = ''/bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done"'';
      ExecStart = ''/bin/sh -c "ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink; ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink"'';
    };
  };
}
