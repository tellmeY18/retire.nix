{ self, config, lib, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    hostName = "next.tellmey.tech";

    # Manually increment with every major upgrade.
    package = pkgs.nextcloud31;

    # Let NixOS install and configure the database automatically.
    database.createLocally = true;

    # Let NixOS install and configure Redis caching automatically.
    configureRedis = true;

    # Increase the maximum file upload size to avoid problems uploading videos.
    maxUploadSize = "16G";

    https = true;

    autoUpdateApps.enable = true;

    extraAppsEnable = true;

    extraApps = with config.services.nextcloud.package.packages.apps; {
      tasks = tasks;
      contacts = contacts;
      memories = memories;
    };

    settings = {
      overwriteprotocol = "https";
      default_phone_region = "IN";
      port = "8789";
    };

    # Additional Nextcloud configuration
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/home/vysakh/entepass";
    };
  };
}

