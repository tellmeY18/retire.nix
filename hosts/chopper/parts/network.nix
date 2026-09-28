# hosts/chopper/parts/network.nix — networking for chopper.
#
# Shared k3s node networking (resolved, firewall FORWARD rules, the
# k3s-pod-routes unit) lives in profiles/k3s-node-network.nix. Only the
# host-specific bits are below.
{ config, ... }:
{
  imports = [ ../../../profiles/k3s-node-network.nix ];

  networking = {
    firewall = {
      allowedUDPPorts = [
        config.services.tailscale.port
        5353 # mDNS — needed for Android TV device discovery (zeroconf)
      ];
      # OpenClaw gateway is exposed via Tailscale Serve (port 443, HTTPS);
      # all legacy web services (Nextcloud, conduwuit, care) bind to
      # localhost and are exposed via Cloudflare Tunnel.
      allowedTCPPorts = [ 22 ];
    };

    # k3s flannel host-gw: route other nodes' pod CIDRs via their Tailscale IPs.
    localCommands = ''
      ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink 2>/dev/null || true
      ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink 2>/dev/null || true
    '';
  };

  # Routes to kenobi (10.42.1.0/24) and c3po (10.42.2.0/24).
  systemd.services.k3s-pod-routes.serviceConfig.ExecStart =
    ''/bin/sh -c "ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink; ip route replace 10.42.2.0/24 via 100.109.132.76 dev tailscale0 onlink"'';
}
