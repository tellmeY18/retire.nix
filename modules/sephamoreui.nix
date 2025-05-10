{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.semaphoreui;

  # Create the configuration file
  configFile = pkgs.writeText "config.json" (builtins.toJSON ({
    port = toString cfg.port;
    interface = cfg.interface;
    tmp_path = cfg.tmpPath;
    cookie_hash = cfg.cookieHash;
    cookie_encryption = cfg.cookieEncryption;
    access_key_encryption = cfg.accessKeyEncryption;
    email_sender = cfg.email.sender;
    email_host = cfg.email.host;
    email_port = cfg.email.port;
    web_host = cfg.webHost;
    ldap_binddn = cfg.ldap.bindDn;
    ldap_bindpassword = cfg.ldap.bindPassword;
    ldap_server = cfg.ldap.server;
    ldap_searchdn = cfg.ldap.searchDn;
    ldap_searchfilter = cfg.ldap.searchFilter;
    ldap_mappings = cfg.ldap.mappings;
    telegram_chat = cfg.telegram.chat;
    telegram_token = cfg.telegram.token;
    concurrency_mode = cfg.concurrencyMode;
    max_parallel_tasks = cfg.maxParallelTasks;
    ssh_config_path = cfg.sshConfigPath;
    demo_mode = cfg.demoMode;
  } // (optionalAttrs (cfg.database.type == "mysql") {
    mysql = {
      host = cfg.database.host;
      user = cfg.database.user;
      pass = cfg.database.password;
      name = cfg.database.name;
      options = cfg.database.options;
    };
  }) // (optionalAttrs (cfg.database.type == "bolt") {
    bolt = {
      host = cfg.database.boltPath;
    };
  })));

  # SemaphoreUI package
  semaphoreui = pkgs.stdenv.mkDerivation rec {
    pname = "semaphoreui";
    version = "2.13.14";

    src = pkgs.fetchurl {
      url = "https://github.com/semaphoreui/semaphore/releases/download/v${version}/semaphore_${version}_linux_amd64.tar.gz";
      sha256 = "sha256-0lcrvSbXRErkK+qVb4qngmovIKJkGPd573RKz6jhkIM=";
    };

    nativeBuildInputs = [ pkgs.gnutar ];

    unpackPhase = ''
      tar xf $src
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp semaphore $out/bin/
      chmod +x $out/bin/semaphore
    '';

    meta = with lib; {
      description = "Modern UI and powerful API for Ansible, Terraform, OpenTofu, PowerShell and other DevOps tools";
      homepage = "https://semaphoreui.com/";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };

in
{
  options.services.semaphoreui = {
    enable = mkEnableOption (lib.mdDoc "SemaphoreUI service");

    package = mkOption {
      type = types.package;
      default = semaphoreui;
      description = lib.mdDoc "The SemaphoreUI package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "semaphore";
      description = lib.mdDoc "User account under which SemaphoreUI runs.";
    };

    group = mkOption {
      type = types.str;
      default = "semaphore";
      description = lib.mdDoc "Group account under which SemaphoreUI runs.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = lib.mdDoc "Port on which SemaphoreUI listens.";
    };

    interface = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc "Interface on which SemaphoreUI listens. Empty string means all interfaces.";
    };

    tmpPath = mkOption {
      type = types.str;
      default = "/tmp/semaphore";
      description = lib.mdDoc "Path for temporary files.";
    };

    webHost = mkOption {
      type = types.str;
      default = "http://localhost:3000";
      description = lib.mdDoc "Web host URL for SemaphoreUI.";
    };

    cookieHash = mkOption {
      type = types.str;
      description = lib.mdDoc "Cookie hash key for session security.";
    };

    cookieEncryption = mkOption {
      type = types.str;
      description = lib.mdDoc "Cookie encryption key.";
    };

    accessKeyEncryption = mkOption {
      type = types.str;
      description = lib.mdDoc "Access key encryption key.";
    };

    concurrencyMode = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc "Concurrency mode (project, node, or empty for no limit).";
    };

    maxParallelTasks = mkOption {
      type = types.int;
      default = 0;
      description = lib.mdDoc "Maximum number of parallel tasks (0 for unlimited).";
    };

    demoMode = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Enable demo mode.";
    };

    sshConfigPath = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc "Path to SSH config file.";
    };

    database = {
      type = mkOption {
        type = types.enum [ "bolt" "mysql" ];
        default = "bolt";
        description = lib.mdDoc "Database type to use. 'bolt' for file-based database, 'mysql' for MySQL/MariaDB.";
      };

      boltPath = mkOption {
        type = types.str;
        default = "/var/lib/semaphore/semaphore.bolt";
        description = lib.mdDoc "Path to BoltDB database file (only used when database.type is 'bolt').";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1:3306";
        description = lib.mdDoc "Database host and port (only used when database.type is 'mysql').";
      };

      user = mkOption {
        type = types.str;
        default = "semaphore";
        description = lib.mdDoc "Database user (only used when database.type is 'mysql').";
      };

      password = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Database password (only used when database.type is 'mysql').";
      };

      name = mkOption {
        type = types.str;
        default = "semaphore";
        description = lib.mdDoc "Database name (only used when database.type is 'mysql').";
      };

      options = mkOption {
        type = types.attrsOf types.str;
        default = {
          parseTime = "true";
          interpolateParams = "true";
        };
        description = lib.mdDoc "Additional database options (only used when database.type is 'mysql').";
      };
    };

    email = {
      sender = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Email sender address.";
      };

      host = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "SMTP host.";
      };

      port = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "SMTP port.";
      };
    };

    ldap = {
      bindDn = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "LDAP bind DN.";
      };

      bindPassword = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "LDAP bind password.";
      };

      server = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "LDAP server URL.";
      };

      searchDn = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "LDAP search DN.";
      };

      searchFilter = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "LDAP search filter.";
      };

      mappings = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = lib.mdDoc "LDAP attribute mappings.";
      };
    };

    telegram = {
      chat = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Telegram chat ID for notifications.";
      };

      token = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Telegram bot token.";
      };
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/semaphore";
      description = lib.mdDoc "Directory to store SemaphoreUI state.";
    };

    playbookPath = mkOption {
      type = types.str;
      default = "/var/lib/semaphore/playbooks";
      description = lib.mdDoc "Path where Ansible playbooks are stored.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Whether to open the firewall for SemaphoreUI.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.cookieHash != "";
        message = "services.semaphoreui.cookieHash must be set";
      }
      {
        assertion = cfg.cookieEncryption != "";
        message = "services.semaphoreui.cookieEncryption must be set";
      }
      {
        assertion = cfg.accessKeyEncryption != "";
        message = "services.semaphoreui.accessKeyEncryption must be set";
      }
      {
        assertion = cfg.database.type == "bolt" || cfg.database.password != "";
        message = "services.semaphoreui.database.password must be set when using MySQL database";
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.stateDir;
      createHome = true;
      description = "SemaphoreUI service user";
    };

    users.groups.${cfg.group} = { };

    environment.systemPackages = [
      cfg.package
      pkgs.ansible
      pkgs.python3
      pkgs.git
      pkgs.openssh
      # Helper script for initial setup
      (pkgs.writeShellScriptBin "semaphore-setup" ''
        set -e
        echo "SemaphoreUI Setup Helper"
        echo "========================"
        echo ""
        echo "Database type: ${cfg.database.type}"
        ${if cfg.database.type == "bolt" then ''
          echo "Using BoltDB file: ${cfg.database.boltPath}"
          echo ""
          echo "Before running SemaphoreUI for the first time, you need to:"
          echo "1. Run database migrations with: sudo -u ${cfg.user} ${cfg.package}/bin/semaphore migrate --config=${configFile}"
          echo "2. Create an admin user with: sudo -u ${cfg.user} ${cfg.package}/bin/semaphore user add --admin --login admin --name Admin --email admin@localhost --password PASSWORD --config=${configFile}"
        '' else ''
          echo "Using MySQL database: ${cfg.database.host}/${cfg.database.name}"
          echo ""
          echo "Before running SemaphoreUI for the first time, you need to:"
          echo "1. Set up your MySQL/MariaDB database"
          echo "2. Run database migrations with: sudo -u ${cfg.user} ${cfg.package}/bin/semaphore migrate --config=${configFile}"
          echo "3. Create an admin user with: sudo -u ${cfg.user} ${cfg.package}/bin/semaphore user add --admin --login admin --name Admin --email admin@localhost --password PASSWORD --config=${configFile}"
        ''}
        echo ""
        echo "Configuration file is located at: ${configFile}"
        echo "State directory: ${cfg.stateDir}"
        echo "Playbooks directory: ${cfg.playbookPath}"
        echo ""
        echo "After setup, start the service with: sudo systemctl start semaphoreui"
        echo "Enable autostart with: sudo systemctl enable semaphoreui"
      '')
    ];

    # Create directories with proper permissions using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.tmpPath} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.playbookPath} 0755 ${cfg.user} ${cfg.group} -"
      # Ensure the directory for BoltDB file exists
      "d ${dirOf cfg.database.boltPath} 0755 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.semaphoreui = {
      description = "SemaphoreUI - Modern UI for Ansible";
      documentation = [ "https://docs.semaphoreui.com/" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "systemd-tmpfiles-setup.service" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/semaphore server --config=${configFile} --log-level DEBUG";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 10;

        # Security settings
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.stateDir cfg.tmpPath cfg.playbookPath (dirOf cfg.database.boltPath) ];

        # Working directory
        WorkingDirectory = cfg.stateDir;

        # Environment
        Environment = [
          "HOME=${cfg.stateDir}"
        ];
      };
    };

    # Open firewall if requested
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ TellmeY18 ];
}
