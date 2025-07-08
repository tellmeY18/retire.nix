{ config, pkgs, lib, ... }:

{
  options = {
    services.arr.enable = lib.mkEnableOption "Enable the full media automation stack (Sonarr, Radarr, Lidarr, Bazarr, Jackett, Jellyfin, Transmission, Flaresolverr)";
  };

  config = lib.mkIf config.services.arr.enable {
    # Create a dedicated group for all media services
    users.groups.torrent.members = [
      "op"
      "sonarr"
      "radarr"
      "bazarr"
      "jackett"
      "lidarr"
      "jellyfin"
      "transmission"
    ];

    # Dedicated user for torrent/media automation
    users.users.torrent = {
      isNormalUser = true;
      extraGroups = [ "wheel" "tty" ];
      home = "/home/torrent";
      homeMode = "0775";
      group = "torrent";
      createHome = true;
      description = "Media automation user";
    };

    # Ensure correct permissions for media directories
    systemd.tmpfiles.rules = [
      "d /home/torrent 0775 torrent torrent -"
      "d /home/torrent/downloads 0775 torrent torrent -"
      "d /home/torrent/downloads/.incomplete 0775 torrent torrent -"
    ];

    # Transmission (BitTorrent client)
    services.transmission = {
      enable = true;
      openFirewall = true;
      openRPCPort = true;
      user = "torrent";
      group = "torrent";
      settings = {
        download-dir = "/home/torrent/downloads";
        incomplete-dir = "/home/torrent/downloads/.incomplete";
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist = "127.0.0.1,10.0.0.1,192.168.*.*,100.64.*.*";
      };
    };

    # Sonarr (TV automation)
    services.sonarr = {
      enable = true;
      openFirewall = true;
      group = "torrent";
    };

    # Radarr (Movies automation)
    services.radarr = {
      enable = true;
      openFirewall = true;
      group = "torrent";
    };

    # Lidarr (Music automation)
    services.lidarr = {
      enable = true;
      openFirewall = true;
      group = "torrent";
    };

    # Bazarr (Subtitles automation)
    services.bazarr = {
      enable = true;
      openFirewall = true;
      group = "torrent";
    };

    # Jackett (Indexer proxy)
    services.jackett = {
      enable = true;
      openFirewall = true;
      group = "torrent";
    };

    # Jellyfin (Media server)
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      group = "torrent";
    };

    # Flaresolverr (Captcha bypass for indexers)
    services.flaresolverr.enable = true;
  };
}
