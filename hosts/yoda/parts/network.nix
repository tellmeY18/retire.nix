# hosts/yoda/parts/network.nix — OCI networking (phase 1: bootstrap).
#
# Phase 1 keeps this minimal: DHCP + SSH reachable over the OCI public IP.
# Tailscale, cross-node pod routes, and k3s firewall rules are added in
# phase 2 (see hosts/kenobi/parts/network.nix for the target shape).
{ ... }:
{
  networking = {
    # Cloud VMs use DHCP — no NetworkManager needed.
    useDHCP = true;

    # OCI VCN uses jumbo frames (MTU 9000) for better throughput.
    # Primary NIC on this instance is ens3 (altname enp0s3).
    interfaces.ens3.mtu = 9000;

    firewall = {
      enable = true;
      # SSH only in phase 1. Tailscale/k3s/Traefik ports come in phase 2.
      allowedTCPPorts = [ 22 ];
    };
  };
}
