{ config, pkgs, lib, ... }:

{
  options.services.nextcloud-chopper = {
    enable = lib.mkEnableOption "Nextcloud instance for chopper host";
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "next.tellmey.tech";
      description = "The hostname for the Nextcloud instance.";
    };
    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Nextcloud admin username.";
    };
    adminPassFile = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = "Path to a file containing the Nextcloud admin password.";
    };
    maxUploadSize = lib.mkOption {
      type = lib.types.str;
      default = "16G";
      description = "Maximum file upload size.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nextcloud31;
      description = "Nextcloud package to use.";
    };
    extraApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "Extra Nextcloud apps to enable.";
    };
    https = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable HTTPS for Nextcloud.";
    };
    port = lib.mkOption {
      type = lib.types.str;
      default = "8789";
      description = "Port for Nextcloud to listen on.";
    };
    dbType = lib.mkOption {
      type = lib.types.enum [ "pgsql" "mysql" "sqlite" ];
      default = "pgsql";
      description = "Database backend for Nextcloud.";
    };
    redis = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Redis caching.";
    };
  };

  config = lib.mkIf config.services.nextcloud-chopper.enable {
    services.nextcloud = {
      enable = true;
      hostName = config.services.nextcloud-chopper.hostName;
      package = config.services.nextcloud-chopper.package;
      database.createLocally = true;
      configureRedis = config.services.nextcloud-chopper.redis;
      maxUploadSize = config.services.nextcloud-chopper.maxUploadSize;
      https = config.services.nextcloud-chopper.https;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = config.services.nextcloud-chopper.extraApps;
      settings = {
        overwriteprotocol = "https";
        default_phone_region = "IN";
        port = config.services.nextcloud-chopper.port;
      };
      config = {
        dbtype = config.services.nextcloud-chopper.dbType;
        adminuser = config.services.nextcloud-chopper.adminUser;
        adminpassFile = config.services.nextcloud-chopper.adminPassFile;
      };
    };
  };
}
