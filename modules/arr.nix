{ self, config, lib, pkgs, ... }:
{
  imports = [ ];
  nixpkgs.overlays = with self.overlays; [
    #flaresolverr
  ];

  users.groups."torrent".members = [
    "op"
    "sonarr"
    "radarr"
    "bazarr"
    "jackett"
    "lidarr"
    "jellyfin"
    "transmission"
  ];

  users.users.torrent = {
    isNormalUser = true;
    extraGroups = [ "wheel" "tty" ];
    homeMode = "775";
  };

  # Fix permissions for torrent user's home directory
  systemd.tmpfiles.rules = [
    "d /home/torrent 0775 torrent torrent -"
    "d /home/torrent/downloads 0775 torrent torrent -"
    "d /home/torrent/downloads/.incomplete 0775 torrent torrent -"
    "Z /home/torrent 0775 torrent torrent -"
  ];

  services.transmission = {
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    user = "torrent";
    settings = {
      download-dir = "/home/torrent/downloads";
      incomplete-dir = "/home/torrent/downloads/.incomplete";
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist = "127.0.0.1,10.0.0.1,192.168.*.*,100.64.*.*";
    };
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "torrent";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "torrent";
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "torrent";
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
    group = "torrent";
  };

  services.jackett = {
    enable = true;
    openFirewall = true;
    group = "torrent";
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
    group = "torrent";
  };

  services.flaresolverr.enable = true;
}
