# NixOS Garage Configuration
{ config, pkgs, ... }:

{
  services.garage = {
    package = pkgs.garage_2;
    enable = true;
    
    # Settings for the Garage daemon
    settings = {
      # Unique identifier for this node
      node_id = "garage-node-1";
      
      # Network configuration
      rpc_bind_addr = "0.0.0.0:3901";
      rpc_public_addr = "127.0.0.1:3901";
      
      # API endpoints
      s3_api = {
        s3_region = "garage";
        api_bind_addr = "0.0.0.0:3900";
        root_domain = ".s3.garage.localhost";
      };
      
      s3_web = {
        bind_addr = "0.0.0.0:3902";
        root_domain = ".web.garage.localhost";
      };
      
      admin = {
        api_bind_addr = "0.0.0.0:3903";
        # Admin token will be loaded from file
        admin_token = "$GARAGE_ADMIN_TOKEN";
      };
      
      # Data storage configuration
      data_dir = "/var/lib/garage/data";
      metadata_dir = "/var/lib/garage/meta";
      
      # Replication settings for Garage 2.x
      replication_factor = 1; # For single-node setup
      consistency_mode = "degraded"; # Allow operation with fewer replicas
      
      # Compression
      compression_level = 1;
      
      # RPC secret will be loaded from file
      rpc_secret = "$GARAGE_RPC_SECRET";
    };
    
    # Load secrets from external files
    environmentFile = "/etc/garage/secrets.env";
  };
  
  # Open necessary ports in the firewall
  networking.firewall.allowedTCPPorts = [
    3900  # S3 API
    3901  # RPC
    3902  # Web interface
    3903  # Admin API
  ];
  
  # Optional: Create a user for garage operations
  users.users.garage = {
    isSystemUser = true;
    group = "garage";
    home = "/var/lib/garage";
    createHome = true;
  };
  
  users.groups.garage = {};
  
  # Ensure proper permissions for data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/garage 0755 garage garage -"
    "d /var/lib/garage/data 0755 garage garage -"
    "d /var/lib/garage/meta 0755 garage garage -"
    "d /etc/garage 0755 root root -"
  ];
  
  # Example secrets file (create this manually on each host)
  environment.etc."garage/secrets.env.example" = {
    text = ''
      # Garage Secrets Configuration
      # Copy this file to /etc/garage/secrets.env and fill in the values
      
      # Admin API token (generate a secure random token)
      GARAGE_ADMIN_TOKEN=your-secure-admin-token-here
      
      # RPC secret key (must be exactly 32 bytes of hex - 64 hex characters)
      # Generate with: openssl rand -hex 32
      GARAGE_RPC_SECRET=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    '';
    mode = "0644";
  };
}
