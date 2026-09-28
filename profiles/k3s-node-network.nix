# profiles/k3s-node-network.nix — networking every k3s node shares.
#
# All five nodes (chopper, c3po, kenobi, r2d2, yoda) repeated these three
# things verbatim. Only the per-host route list actually differs.
#
# WHAT LIVES HERE
#   - systemd-resolved for split-DNS (Tailscale routes .ts.net via MagicDNS)
#   - firewall: trust tailscale0 + cni0, and the FORWARD rules that let
#     cross-node pod traffic through
#   - the k3s-pod-routes unit, MINUS its ExecStart
#
# WHAT STAYS PER-HOST
#   - serviceConfig.ExecStart on k3s-pod-routes — the actual `ip route replace`
#     lines, which name every OTHER node's pod CIDR and Tailscale IP
#   - firewall ports, MTU, useDHCP, tailscale extraUpFlags, localCommands
#   - kenobi's extra `bindsTo = [ "k3s.service" ]`
#
# Deliberately NOT gated behind services.k3s-cluster.enable: yoda declares
# this networking while its k3s enablement is still off.
{ pkgs, ... }:
{
  # systemd-resolved for split-DNS — Tailscale configures the tailscale0
  # link to route .ts.net queries through 100.100.100.100 (MagicDNS),
  # while everything else goes through upstream DNS.
  services.resolved = {
    enable = true;
    # Fallback DNS if upstream is unavailable.
    settings.Resolve.FallbackDNS = [ "8.8.8.8" "1.1.1.1" ];
  };

  networking.firewall = {
    enable = true;

    # Trust the tailnet + pod bridge interfaces.
    #
    # NOTE: factoring this out of the per-host modules changes the ORDER in
    # which it merges with modules/services/k3s.nix's own `cni0` entry, so
    # the generated firewall script lists the -i <iface> accept rules in a
    # different order than before. Every entry is an ACCEPT on a trusted
    # interface, so order carries no meaning — the resulting rule SET is
    # identical. (Verified by diffing the sorted firewall rules.)
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

  # Cross-node pod CIDR routes — added AFTER tailscale is online, because
  # networking.localCommands runs before tailscale0 exists.
  #
  # Each host must set serviceConfig.ExecStart with its own routes.
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
    # forever (stderr swallowed), wedging switch-to-configuration and every
    # subsequent deploy.
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = ''/bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done"'';
    };
  };
}
