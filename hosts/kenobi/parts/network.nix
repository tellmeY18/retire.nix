# OCI networking for kenobi.
# - DHCP on the primary interface (enp0s6)
# - Jumbo frames (MTU 9000) preserved for OCI VCN performance
# - Firewall: public-facing ports (SSH, HTTP, HTTPS) + Tailscale
{ config, ... }:
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
      # Trust the tailnet interface — all cluster traffic rides here
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # Tailscale for cluster connectivity
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns=false"
    ];
    openFirewall = true;
  };
}
