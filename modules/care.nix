{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.care;
  carePgUser = "care";
  carePgDatabase = "care";
  careImage = "ghcr.io/ohcnetwork/care:latest";

  garageEnvContent = ''
    GARAGE_ADMIN_TOKEN_FILE=/etc/care/secrets/garage_admin_token
    GARAGE_RPC_SECRET_FILE=/etc/care/secrets/garage_rpc_secret
  '';

in
{
  options.services.care = {
    enable = mkEnableOption (mdDoc "Enable CARE service (PostgreSQL + Garage S3 storage + CARE containers)");

    database = {
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "PostgreSQL host";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port";
      };

      name = mkOption {
        type = types.str;
        default = carePgDatabase;
        description = "PostgreSQL database name";
      };

      user = mkOption {
        type = types.str;
        default = carePgUser;
        description = "PostgreSQL username";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to create the database locally";
      };
    };

    redis = {
      url = mkOption {
        type = types.str;
        default = "redis://localhost:6379/0";
        description = "Redis URL for Django";
      };
    };

    celery = {
      brokerUrl = mkOption {
        type = types.str;
        default = "redis://localhost:6379/1";
        description = "Celery broker URL";
      };
    };

    django = {
      settingsModule = mkOption {
        type = types.str;
        default = "config.settings.staging";
        description = "Django settings module";
      };

      secureSslRedirect = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Django SSL redirect";
      };

      adminUrl = mkOption {
        type = types.str;
        default = "admin/";
        description = "Django admin URL path";
      };

      allowedHosts = mkOption {
        type = types.listOf types.str;
        default = [ "localhost" "127.0.0.1" "0.0.0.0" ];
        description = "Django allowed hosts";
      };
    };

    cors = {
      allowedOrigins = mkOption {
        type = types.listOf types.str;
        default = [ "http://localhost:9000" "http://127.0.0.1:9000" ];
        description = "CORS allowed origins";
      };

      trustedOrigins = mkOption {
        type = types.listOf types.str;
        default = [ "http://localhost:9000" "http://127.0.0.1:9000" ];
        description = "CSRF trusted origins";
      };
    };

    storage = {
      provider = mkOption {
        type = types.str;
        default = "garage";
        description = "Storage provider";
      };

      region = mkOption {
        type = types.str;
        default = "garage";
        description = "Storage region";
      };

      accessKey = mkOption {
        type = types.str;
        default = "care-access-key";
        description = "S3 access key";
      };

      uploadBucket = mkOption {
        type = types.str;
        default = "care-uploads";
        description = "File upload bucket name";
      };

      facilityBucket = mkOption {
        type = types.str;
        default = "care-facilities";
        description = "Facility bucket name";
      };

      endpoint = mkOption {
        type = types.str;
        default = "http://localhost:3900";
        description = "S3 endpoint URL";
      };
    };

    security = {
      rateLimit = mkOption {
        type = types.str;
        default = "5/10m";
        description = "API rate limit";
      };
    };

    sentry = {
      profilesSampleRate = mkOption {
        type = types.float;
        default = 0.5;
        description = "Sentry profiles sample rate";
      };

      tracesSampleRate = mkOption {
        type = types.float;
        default = 0.5;
        description = "Sentry traces sample rate";
      };

      environment = mkOption {
        type = types.str;
        default = "nixos-dev";
        description = "Sentry environment";
      };

      dsn = mkOption {
        type = types.str;
        default = "";
        description = "Sentry DSN";
      };
    };

    jwt = {
      jwksBase64 = mkOption {
        type = types.str;
        default = "eyJrZXlzIjogW3sibiI6ICJtQ3lmc29yQXRGOUR4MTBCZWhfcmxvWFNZMms2VEU0V2JTcWZZTGl5OVZ0Q0ZiNmZUYldicmF2SG9MSHZSTUhVQkJGaHYtOHdEYzBUWjZsVG1xd2RqWkdoQlVPc1Z2SFV2OUlBTm9aNk4ycmdrVUp1VFBFeGJtb0pZSk8zTWtVYzNMcDVYUHNFeWd6MXJTcllfdFZKbXlRSHFpVHVXMGE5My15X0cxekw0X0oxNFpjVzhnZWQwNk4xQXhOYkRrbmZZeVd4X0FocjNlRmNhMmR5Q3ZVUXNSQTI2Vy1OQ0JudWdWZUhYQm5hcUZJaDVoSV9lZWh6ZW5wOVNockJIWkJURldHOS1TYXNEVEdwbU45N21kNHFDeDZibkxBelRpVVpBQzlrb1piaXY4dFZSQWszU3NtRk1adDdIN0tURFBUXzZfakt2a2hYV1hMUFZRT0JUbC1zc1EiLCAiZSI6ICJBUUFCIiwgImQiOiAid1Rsb1RqMEJGQWNpLVRLUGZaS3FnaWJLVHBCX0JnVGhWUnlaNHlhamxnaWFrU0hMQmRGa0s5SERXYmlXS0tnMW5qU3otaEtzNGRsVW1udlhQTDd2aDZNeTRveGJlTXI1YWRndGpRNlVnV21rWE00TllJV2lUcUUxNXZ1cDBwc1BXdmNzdzNPNVVSWERubTZadW5yNVM1VWtabGNla2FmeDBUTzhOZkpPc3RCbXN1Vmd2OGkzbE5Nc0hYWnZ4WnJ5Vm5ueGRzSzdKRTlyY2RYWXVqQm5BS01WSjZ1cTMzUUY4UEpWSzdrdUhSM3RGUVNkVDNkUVk5a2ExUjRkYURMeGhqeEt5aGV4ZU9nS1VvT20xQ1RMMDdYQm11UVZ1cEFQWkxnbkstRlhSY2l0RE5hNjNEOFhsZGpsa3hWWEZGdjlLWTN3a1Y4bkdaUnJ6ZlRSdUotQiIsICJwIjogInlFR1pmcktlUnZoQTR0RUZMSTQ2dW9TREtOeF9PLUdvbmM3ZGtLNG05bnd2UzlqTXg1NWlEaEhfbExtR0l3Q2VFWm82WF9GR0lmYUxYYVpJdWQzOXd2V2hiWEFsMUc5ZGhOT1dkUVZTTm9LVzYtMVRuRmhsTjZ5LXdzbDlnWFpvS1pwLUhzR2Z3Y1BWa1NuckE5YlZob3puSklpRG5MYlZTMFdud0d6dFVvRSIsICJxIjogIndvaXItWDQ4NjBSS3NpTmhMV0ZjZnRlQ1hxU2VEU29Eb3JMNnd2R1NzRWQwQmR1R0JLRE00S3B1MFI4UUVjS0tpZW05YnlZZ3hMVkdHZ2ktN0RUWFdDNHVCcFhMRHBoSllQd3NXYVJQbXllb1dsVlJnMU1uWEtqcUJrcmJacFNsbkZBWXV5ZGhCdkg2NDk1MjJyeDgxNXowaDBCXzVEX2tJY0g3Q05tZDRqRSIsICJkcCI6ICJ1d0FfSlFnSk0zNjVvTlROUHhrbUVHeVR5a0YxY3VhN3ZYbWlmMnVSS05VNG1Wd19oaDBKdGRmcTBlZ1pNWEJ2SzBMWlJpU1plRGV4VnVkanZHVm5oWG80bjJoOWV3M3Z4NHlLVUlhQ2lqS1NXb2dKYnROQTJhZXZqMWYyb2tGLTdYSy1XVnc0SWdvTTBmelI0SWpxWmpZSDFwN0FRRVNma3lYZGk1eHNWWUUiLCAiZHEiOiAiVDRHT1RfVGhMd0tGU05NZTUyNHdZSUx4X0g1cFBsWWFrRWQ0SjI2V0ZrZk55b3NTOWhkR1JOaERYR0xHcll1R0ZhR2JVNjhRbTNTX0J1cm1KU0hmbFdHaVdfeWl0ZjlWbGpiYVpYUzdPRjEzLUJ1QXFoeTFMTEM0blFQQk1lYTAzUEw3ZUpvNmxKMFhma1F3N1dzMTF1V0dKelVjVUF3d3pfODQtel85d0RFIiwgInFpIjogIkZNaWwwRV9Ucl9vUEJ0c0tYalZfSml6MDlVT1dmekRIQUtuNTllNlNscDhqRVg1VXRwajZlWUQtcVQ2VGs3bmJleGJwTF94aU1fd0xndDJKbmt2bTk5UVlmcVJJTi1fSG1lME0wbXhHbG91Y1NreVlfNTN6M0tQeTA4RGU3M2hYek80aGZuV0dQd3VaMndfcVpnYjZZQ3pMVTZfWHBFOTRLTjZCMk5mUEFIMCIsICJrdHkiOiAiUlNBIiwgImtpZCI6ICJ6ZlBWNF9TdTZSbS1EUHFjQmJGN0tCSUl1QVp0ejFUd0xRdk8xX01LS2tjIiwgImFsZyI6ICJSUzI1NiJ9XX0=";
        description = "JWT JWKS base64 encoded";
      };
    };

    containers = {
      image = mkOption {
        type = types.str;
        default = careImage;
        description = "Docker image for CARE containers";
      };
    };

    environmentFileContent = mkOption {
      type = types.lines;
      description = "The content for the care.env file. The default is generated from other options.";
      default = ''
        # PostgreSQL Configuration
        POSTGRES_DB=${cfg.database.name}
        POSTGRES_USER=${cfg.database.user}
        POSTGRES_HOST=${cfg.database.host}
        POSTGRES_PORT=${toString cfg.database.port}

        # Database URL (Django format) - password will be substituted at runtime
        DATABASE_URL=postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}

        # Redis Configuration
        REDIS_URL=${cfg.redis.url}

        # Celery Configuration
        CELERY_BROKER_URL=${cfg.celery.brokerUrl}

        # Django Configuration
        DJANGO_SETTINGS_MODULE=${cfg.django.settingsModule}
        DJANGO_SECURE_SSL_REDIRECT=${if cfg.django.secureSslRedirect then "True" else "False"}
        DJANGO_ADMIN_URL=${cfg.django.adminUrl}
        DJANGO_ALLOWED_HOSTS=${builtins.toJSON cfg.django.allowedHosts}

        # CORS Configuration
        CORS_ALLOWED_ORIGINS=${builtins.toJSON cfg.cors.allowedOrigins}
        CSRF_TRUSTED_ORIGINS=${builtins.toJSON cfg.cors.trustedOrigins}

        # S3/Garage Configuration
        BUCKET_PROVIDER=${cfg.storage.provider}
        BUCKET_REGION=${cfg.storage.region}
        BUCKET_KEY=${cfg.storage.accessKey}
        FILE_UPLOAD_BUCKET=${cfg.storage.uploadBucket}
        FACILITY_S3_BUCKET=${cfg.storage.facilityBucket}
        FILE_UPLOAD_BUCKET_ENDPOINT=${cfg.storage.endpoint}
        FACILITY_S3_BUCKET_ENDPOINT=${cfg.storage.endpoint}

        # Rate Limiting
        RATE_LIMIT=${cfg.security.rateLimit}

        # Sentry Configuration
        SENTRY_PROFILES_SAMPLE_RATE=${toString cfg.sentry.profilesSampleRate}
        SENTRY_TRACES_SAMPLE_RATE=${toString cfg.sentry.tracesSampleRate}
        SENTRY_ENVIRONMENT=${cfg.sentry.environment}
        SENTRY_DSN=${cfg.sentry.dsn}

        # JWT Configuration
        JWKS_BASE64=${cfg.jwt.jwksBase64}

        ${cfg.extraEnvironment}
      '';
    };

    extraEnvironment = mkOption {
      type = types.lines;
      default = "";
      description = "Extra environment variables to add to care.env. Note: if you override `environmentFileContent`, you must manually append this value if desired.";
    };

    secrets = {
      autoGenerate = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to auto-generate secrets";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Podman and OCI containers
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Enable OCI container backend (uses Podman)
    virtualisation.oci-containers.backend = "podman";

    # Enable Redis for Celery and caching
    services.redis.servers."" = {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
      settings = {
        maxmemory = "256mb";
        maxmemory-policy = "allkeys-lru";
      };
    };

    # PostgreSQL configuration (only if creating locally)
    services.postgresql = mkIf cfg.database.createLocally {
      enable = mkDefault true;
      enableTCPIP = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
        }
      ];
    };

    # Garage S3 storage configuration
    services.garage = {
      package = pkgs.garage_2;
      enable = true;
      settings = {
        node_id = "garage-node-1";
        rpc_bind_addr = "0.0.0.0:3901";
        rpc_public_addr = "127.0.0.1:3901";

        s3_api = {
          s3_region = cfg.storage.region;
          api_bind_addr = "0.0.0.0:3900";
          root_domain = ".s3.garage.localhost";
        };

        s3_web = {
          bind_addr = "0.0.0.0:3902";
          root_domain = ".web.garage.localhost";
        };

        admin = {
          api_bind_addr = "0.0.0.0:3903";
          admin_token = "$GARAGE_ADMIN_TOKEN";
        };

        data_dir = "/var/lib/garage/data";
        metadata_dir = "/var/lib/garage/meta";
        replication_factor = 1;
        consistency_mode = "degraded";
        compression_level = 1;
        rpc_secret = "$GARAGE_RPC_SECRET";
      };
      environmentFile = "/etc/care/garage.env";
    };

    # Network configuration
    networking.firewall.allowedTCPPorts = [ 3900 3901 3902 3903 6379 9000 ];

    # User and directory setup
    users.users.garage = {
      isSystemUser = true;
      group = "garage";
      home = "/var/lib/garage";
      createHome = true;
    };

    users.groups.garage = { };

    # Secrets management using systemd.tmpfiles.d for permission management
    systemd.tmpfiles.rules = [
      "d /etc/care/secrets 0750 root root -"
      "d /var/lib/garage 0755 garage garage -"
      "d /var/lib/garage/data 0755 garage garage -"
      "d /var/lib/garage/meta 0755 garage garage -"
      "d /run/care 0755 root root -"
      "r /run/care/care.env - - - - -" # Purge leftover runtime env file at boot
    ];

    # Secret generation service (only generates what doesn't exist)
    systemd.services.care-secrets = mkIf cfg.secrets.autoGenerate {
      description = "Generate CARE secrets";
      wantedBy = [ "multi-user.target" ];
      before = [
        "postgresql.service"
        "garage.service"
        "redis.service"
        "podman-care-api.service"
        "podman-care-celery-worker.service"
        "podman-care-celery-beat.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
        UMask = "0077"; # Ensure secrets are created with restrictive permissions
      };
      script = ''
        # Function to generate secret if it doesn't exist
        generate_secret() {
          local file="$1"
          local generator="$2"

          if [ ! -f "$file" ]; then
            echo "Generating secret: $file"
            eval "$generator" > "$file"
            chmod 600 "$file"
          fi
        }

        # Generate individual secrets
        generate_secret "/etc/care/secrets/postgres_password" "${pkgs.openssl}/bin/openssl rand -base64 32 | tr -d '\n'"
        generate_secret "/etc/care/secrets/django_secret_key" "${pkgs.openssl}/bin/openssl rand -base64 50 | tr -d '\n'"
        generate_secret "/etc/care/secrets/garage_admin_token" "${pkgs.openssl}/bin/openssl rand -base64 32 | tr -d '\n'"
        generate_secret "/etc/care/secrets/garage_rpc_secret" "${pkgs.openssl}/bin/openssl rand -hex 32 | tr -d '\n'"
        generate_secret "/etc/care/secrets/bucket_secret" "${pkgs.openssl}/bin/openssl rand -base64 32 | tr -d '\n'"

        # Set specific permissions for garage secrets so the garage user can read them
        chown root:garage /etc/care/secrets/garage_admin_token /etc/care/secrets/garage_rpc_secret
        chmod 640 /etc/care/secrets/garage_admin_token /etc/care/secrets/garage_rpc_secret
      '';
    };

    # PostgreSQL setup service
    systemd.services.care-postgres-setup = mkIf cfg.database.createLocally (
      let
        pgUserEscaped = lib.escapeShellArg cfg.database.user;
        pgDatabaseEscaped = lib.escapeShellArg cfg.database.name;
      in
      {
        description = "CARE PostgreSQL setup";
        wantedBy = [ "multi-user.target" ];
        after = [ "postgresql.service" "care-secrets.service" ];
        requires = [ "postgresql.service" "care-secrets.service" ];
        before = [ "care-env-wrapper.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "root";
          Group = "root";
        };
        script = ''
          # Wait for PostgreSQL to be ready
          echo "Waiting for PostgreSQL service to be ready..."
          timeout=60
          counter=0
          until ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_isready -q; do
            if [ $counter -ge $timeout ]; then
              echo "ERROR: PostgreSQL failed to become ready within $timeout seconds"
              exit 1
            fi
            echo "PostgreSQL not ready yet, waiting... ($counter/$timeout)"
            sleep 1
            counter=$((counter + 1))
          done
          echo "PostgreSQL service is ready."

          # Read password from secret file
          POSTGRES_PASSWORD=$(cat /etc/care/secrets/postgres_password)

          # Create/update user with password
          USER_EXISTS=$(${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -tAc "SELECT 1 FROM pg_roles WHERE rolname=${pgUserEscaped}" 2>/dev/null | grep -c 1 || echo "0")
          if [ "$USER_EXISTS" = "0" ]; then
            echo "Creating PostgreSQL user ${pgUserEscaped}..."
            ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "CREATE USER ${pgUserEscaped} WITH PASSWORD '$POSTGRES_PASSWORD';"
          else
            echo "User ${pgUserEscaped} already exists, updating password..."
            ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "ALTER USER ${pgUserEscaped} WITH PASSWORD '$POSTGRES_PASSWORD';"
          fi

          # Create/update database
          DB_EXISTS=$(${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -tAc "SELECT 1 FROM pg_database WHERE datname=${pgDatabaseEscaped}" 2>/dev/null | grep -c 1 || echo "0")
          if [ "$DB_EXISTS" = "0" ]; then
            echo "Creating PostgreSQL database ${pgDatabaseEscaped}..."
            ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "CREATE DATABASE ${pgDatabaseEscaped} OWNER ${pgUserEscaped};"
          else
            echo "Database ${pgDatabaseEscaped} already exists, ensuring correct owner..."
            ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "ALTER DATABASE ${pgDatabaseEscaped} OWNER TO ${pgUserEscaped};"
          fi

          # Grant privileges
          ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE ${pgDatabaseEscaped} TO ${pgUserEscaped};"

          echo "PostgreSQL setup completed successfully."
        '';
      }
    );

    # Declaratively create configuration files
    environment.etc = {
      "care/garage.env" = {
        text = garageEnvContent;
        mode = "0640";
        group = "garage";
      };
    };

    # Container wrapper script that substitutes secrets at runtime
    systemd.services.care-env-wrapper = {
      description = "Generate runtime CARE environment with secrets";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f /run/care/care.env"; # Purge leftover env file before generating
      };
      script = ''
        # Start with the base environment content
        cat > /run/care/care.env << 'EOF'
        ${cfg.environmentFileContent}
        EOF

        # Add secrets to the environment file
        if [ -f /etc/care/secrets/postgres_password ]; then
          POSTGRES_PASSWORD=$(cat /etc/care/secrets/postgres_password)
          echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> /run/care/care.env
          # Update DATABASE_URL with the actual password
          sed -i "s|postgresql://${cfg.database.user}@|postgresql://${cfg.database.user}:$POSTGRES_PASSWORD@|g" /run/care/care.env
        fi

        # Add other secret substitutions
        if [ -f /etc/care/secrets/django_secret_key ]; then
          echo "DJANGO_SECRET_KEY=$(cat /etc/care/secrets/django_secret_key)" >> /run/care/care.env
        fi

        if [ -f /etc/care/secrets/bucket_secret ]; then
          echo "BUCKET_SECRET=$(cat /etc/care/secrets/bucket_secret)" >> /run/care/care.env
        fi

        chmod 640 /run/care/care.env
      '';
      wantedBy = [ "multi-user.target" ];
      before = [ "podman-care-api.service" "podman-care-celery-worker.service" "podman-care-celery-beat.service" ];
      after = [ "care-secrets.service" ] ++ optional cfg.database.createLocally "care-postgres-setup.service";
      requires = [ "care-secrets.service" ] ++ optional cfg.database.createLocally "care-postgres-setup.service";
    };

    # CARE containers with proper dependencies
    virtualisation.oci-containers.containers = {
      care-celery-beat = {
        image = cfg.containers.image;
        cmd = [ "/app/celery_beat.sh" ];
        environmentFiles = [ "/run/care/care.env" ];
        autoStart = true;
        extraOptions = [ "--network=host" ]; # Removed --pull=always
      };

      care-api = {
        image = cfg.containers.image;
        cmd = [ "/app/start.sh" ];
        ports = [ "9000:9000" ];
        environmentFiles = [ "/run/care/care.env" ];
        autoStart = true;
        extraOptions = [ "--network=host" ]; # Removed --pull=always
      };

      care-celery-worker = {
        image = cfg.containers.image;
        cmd = [ "/app/celery_worker.sh" ];
        environmentFiles = [ "/run/care/care.env" ];
        autoStart = true;
        extraOptions = [ "--network=host" ]; # Removed --pull=always
      };
    };

    # Proper service dependencies
    systemd.services."podman-care-celery-beat" = {
      after = [ "garage.service" "redis.service" "care-env-wrapper.service" ];
      requires = [ "care-env-wrapper.service" "garage.service" "redis.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services."podman-care-api" = {
      after = [ "podman-care-celery-beat.service" ];
      requires = [ "podman-care-celery-beat.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services."podman-care-celery-worker" = {
      after = [ "podman-care-celery-beat.service" ];
      requires = [ "podman-care-celery-beat.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}

