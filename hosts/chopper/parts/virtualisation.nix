{ pkgs, ... }:
{
  virtualisation = {
    docker = {
      enable = true;
      extraPackages = with pkgs; [
        docker-buildx # Explicitly include buildx
      ];
      daemon.settings = {
        dns = [
          "8.8.8.8" # Google (works well in India)
          "1.1.1.1" # Cloudflare (fast in India)
          "208.67.222.222" # OpenDNS
          "9.9.9.9" # Quad9
        ];
      };
    };
    podman = {
      enable = false;
      dockerCompat = true;
    };
  };
}
