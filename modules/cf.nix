#{ config, lib, pkgs, ... }:
#
#let
#  # Define your domain name here
#  domain = "next.tellmey.tech";
#in
#{
#  # Ensure nextcloud config knows about the external domain
#  services.nextcloud = {
#    # Update the hostname to your domain
#    # Add your domain to trusted domains
#    config = {
#      trustedDomains = [ domain "localhost" ];
#      overwriteProtocol = "https";
#    };
#  };
#  
#  # Configure the built-in cloudflared module
#  services.cloudflared = {
#    enable = true;
#    
#    # Tunnel authentication - you'll need to create this file
#    # Run: cloudflared tunnel login
#    # Run: cloudflared tunnel create nextcloud-tunnel
#    # This will create a credentials file you need to reference here
#    tunnelCredentialsFile = "/home/vysakh/.cloudflared/b0ca1206-1d09-4892-9d69-d3a196877013.json.";
#    
#    # Your tunnel ID from the credentials file
#    tunnelId = "b0ca1206-1d09-4892-9d69-d3a196877013"; # Replace with your actual tunnel ID
#    
#    # Ingress rules for your tunnel
#    ingress = {
#      # Route all traffic to your Nextcloud instance
#      rules = [
#        {
#          hostname = domain;
#          service = "https://localhost:${toString config.services.nextcloud.settings.port}";
#        }
#        # Catch-all rule (required)
#        {
#          service = "http_status:404";
#        }
#      ];
#    };
#  };
#  
##  # Optional: systemd dependency to ensure nextcloud is ready before cloudflared starts
##  systemd.services.cloudflared = {
##    requires = [ "nextcloud-setup.service" ];
##    after = [ "nextcloud-setup.service" ];
##  };
#  
##  # Ensure networking allows the required connections
##  networking.firewall = {
##    enable = true;
##    # No need to open external ports as cloudflared creates an outbound tunnel
##  };
#}
