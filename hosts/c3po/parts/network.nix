# hosts/c3po/parts/network.nix — Networking for c3po (k3s server + Tailscale)
#
# Shared k3s node networking lives in profiles/k3s-node-network.nix.
# c3po is on WiFi, so it also gates k3s on tailscale0 actually being UP
# (profiles/tailscale-online.nix).
{ config, ... }:
{
  imports = [
    ../../../profiles/k3s-node-network.nix
    ../../../profiles/tailscale-online.nix
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];

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

  # c3po gets podCIDR 10.42.2.0/24; route to chopper (10.42.0.0/24) and
  # kenobi (10.42.1.0/24).
  systemd.services.k3s-pod-routes.serviceConfig.ExecStart =
    ''/bin/sh -c "ip route replace 10.42.0.0/24 via 100.107.213.17 dev tailscale0 onlink; ip route replace 10.42.1.0/24 via 100.73.101.89 dev tailscale0 onlink"'';
}
