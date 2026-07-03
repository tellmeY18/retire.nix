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
{ config, pkgs, ... }:
{
  networking = {
    # Cloud VMs use DHCP — no NetworkManager needed.
    useDHCP = true;

    firewall = {
      enable = true;
      # Compute node — no public HTTP/HTTPS. SSH only on the public iface.
      allowedTCPPorts = [ 22 ];
      # Trust the tailnet + pod bridge interfaces.
      trustedInterfaces = [
        "tailscale0"
        "cni0"
      ];

      # Allow forwarding between tailscale0 and pod networks (cni0).
      # MUST use -I (insert at top) because kube-router's FORWARD rules run
      # first and drop cross-node pod traffic arriving via tailscale0.
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
      "--accept-dns=false"
      # Advertise this node's pod CIDR so peers can route to our pods.
      "--advertise-routes=10.42.3.0/24"
    ];
  };

  # ---------------------------------------------------------------------------
  # Ensure tailscale0 is UP before k3s starts.
  #
  # k3s is ordered after tailscaled.service, but that only means the daemon is
  # running — NOT that the WireGuard tunnel is up and tailscale0 has its IP. If
  # k3s starts before tailscale0 exists, flannel (--flannel-iface=tailscale0)
  # can't find its interface and the node stays NotReady permanently.
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
    # unit exits 127 and fails activation, triggering a deploy-rs rollback.
    path = [
      pkgs.coreutils
      pkgs.bash
      pkgs.iproute2
      pkgs.gnugrep
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''/bin/sh -c "timeout 90 sh -c 'until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done'"'';
    };
  };

  # Cross-node pod CIDR routes — added after tailscale is online.
  # yoda gets podCIDR 10.42.3.0/24 from the control plane; it needs routes to
  # every OTHER node's pod CIDR via that node's Tailscale IP (host-gw).
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
      ExecStart = ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink; ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink"'';
    };
  };
}
