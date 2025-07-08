{ config, lib, pkgs, ... }:

{
  options.services.cockpit = {
    enable = lib.mkEnableOption "Cockpit web-based server manager";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the firewall for Cockpit's web interface (port 9090).";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Extra settings for Cockpit's WebService section.";
    };
  };

  config = lib.mkIf config.services.cockpit.enable {
    services.cockpit = {
      enable = true;
      settings = config.services.cockpit.settings // {
        WebService = config.services.cockpit.settings.WebService or {
          AllowUnencrypted = true;
        };
      };
    };

    networking.firewall = lib.mkIf config.services.cockpit.openFirewall {
      allowedTCPPorts = [ 9090 ];
    };
  };
}
