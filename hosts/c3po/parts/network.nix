# hosts/c3po/parts/network.nix — Networking for c3po (k3s server + Tailscale)
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
    openFirewall = true;
    # Opens the WireGuard UDP port — required for direct
    # peer connections. Without this, Tailscale falls back
    # to DERP relay and flannel host-gw can't initialize.
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
      "--advertise-routes=10.42.2.0/24"
    ];
  };

  # ---------------------------------------------------------------------------
  # Ensure tailscale0 is UP before k3s starts.
  #
  # The k3s module orders k3s after tailscaled.service, but that only means the
  # daemon is running — NOT that the WireGuard tunnel is established and
  # tailscale0 has its IP. On WiFi (c3po), the interface can take 10–30s to
  # appear after tailscaled starts. If k3s starts before tailscale0 exists,
  # flannel (--flannel-iface=tailscale0) fails to find its interface and the
  # node stays NotReady permanently.
  #
  # This gate service blocks k3s until tailscale0 is UP with an IP.
  # ---------------------------------------------------------------------------
  systemd.services.tailscale-online = {
    description = "Wait for tailscale0 interface to be UP";
    after = [
      "tailscaled.service"
      "network-online.target"
    ];
    requires = [ "tailscaled.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "k3s.service" ];
    # coreutils (timeout/sleep), bash (sh), iproute2 (ip), gnugrep (grep) must
    # be on PATH — the ExecStart shells out to all of them. Without this the
    # unit exits 127 ("sh: No such file or directory"), which fails activation
    # and triggers a deploy-rs rollback.
    path = [
      pkgs.coreutils
      pkgs.bash
      pkgs.iproute2
      pkgs.gnugrep
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Wait up to 90s for tailscale0 to appear and have RUNNING state.
      # WiFi association + DHCP + Tailscale handshake can take 30–60s.
      ExecStart = ''/bin/sh -c "timeout 90 sh -c 'until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done'"'';
    };
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
    # iproute2 must be on PATH — ExecStartPre/ExecStart use `ip`. Without it
    # the `until ip link show ... UP` loop runs `ip: command not found`
    # forever, wedging switch-to-configuration and every subsequent deploy.
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = ''/bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done"'';
      ExecStart = ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink"'';
    };
  };
}
