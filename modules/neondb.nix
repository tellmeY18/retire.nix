{ config, lib, pkgs, ... }:

let
  cfg = config.services.neondb;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options.services.neondb = {
    enable = mkEnableOption "neondb";
    package = mkOption {
      type = types.package;
      default = pkgs.neondb;
      description = "neondb package to use";
    };
    tenant = mkOption {
      type = types.str;
      default = "default";
      description = "Default tenant";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/neondb";
      description = "Data directory for neondb";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.neondb = {
      description = "neondb server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/neon_local \
            --tenant-id ${cfg.tenant} \
            -D ${cfg.dataDir} \
            start
        '';
        User = "neondb";
        Group = "neondb";
        Restart = "on-failure";
        # TODO: Other service config
      };
    };

    users.users.neondb = {
      isSystemUser = true;
      group = "neondb";
      home = cfg.dataDir;
    };
    users.groups.neondb = { };
  };
}

