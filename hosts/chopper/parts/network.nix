{ config, ... }:
{
  networking = {
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    resolvconf = {
      enable = true;
      # Override Tailscale DNS management
      extraConfig = ''
        name_servers="8.8.8.8 1.1.1.1"
      '';
    };
    firewall = {
      enable = true;
      allowedUDPPorts = [ config.services.tailscale.port ];
      trustedInterfaces = [ "tailscale0" ];
      # SSH only; all web services (Nextcloud, conduwuit, care) bind to
      # localhost and are exposed exclusively via Cloudflare Tunnel.
      allowedTCPPorts = [ 22 ];
      # Uncomment if running services without Cloudflare Tunnel:
      # allowedTCPPorts = [ 22 80 443 ];
    };
  };
}
