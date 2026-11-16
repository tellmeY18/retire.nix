# hosts/chopper/parts/network.nix — networking for chopper (workstation).
#
# Chopper left the k3s cluster on 2026-11-16: no pod routes, no CNI
# forwarding rules. systemd-resolved stays for Tailscale MagicDNS split-DNS.
{ config, ... }:
{
  services.resolved.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ 22 ];
  };
}
