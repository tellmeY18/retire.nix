{ config, pkgs, lib, ... }:



{
  # Set the system state version for NixOS upgrades
  system = {
    stateVersion = "24.11";
  };

  ####################
  # Bootloader Setup #
  ####################
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    ####################
    # ZFS Overrides    #
    ####################
    zfs = {
      package = lib.mkForce pkgs.zfs_unstable;
      forceImportAll = lib.mkForce true;
    };
  };

  services = {
    ####################
    # Users & SSH      #
    ####################
    neondb = {
      enable = true;
      package = pkgs.neondb;
      defaultPostgresPackage = pkgs.neondb.postgresql_16;
      users = {
        nextcloud = {
          passwordFile = "/home/vysakh/entepass";
          superuser = false;
          createdb = true;
          login = true;
        };
        care = {
          passwordFile = "/home/vysakh/carepass";
          superuser = false;
          createdb = true;
          login = true;
        };
      };
    };
    tlp = {
      enable = true;
      # See https://linrunner.de/tlp/settings/ for all available options.
      # These are some common settings for fine-tuning power management on laptops.
      settings = {
        # Set the default mode and enable TLP.
        TLP_DEFAULT_MODE = "AC";
        TLP_ENABLE = 1;

        # --- CPU Tuning ---
        # Use 'performance' governor on AC for responsiveness,
        # and 'powersave' on battery for longevity.
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # Allow CPU to reach max performance on AC.
        # Prevent CPU from using "turbo boost" on battery to save power.
        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;

        # Set energy performance hints.
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # --- Disk / Filesystem ---
        # Minimize disk power saving on AC for faster access.
        # Use medium power saving on battery.
        DISK_APM_LEVEL_ON_AC = "254";
        DISK_APM_LEVEL_ON_BAT = "128";

        # SATA link power management. 'max_performance' on AC, 'min_power' on battery.
        SATA_LINKPWR_ON_AC = "max_performance";
        SATA_LINKPWR_ON_BAT = "min_power";

        # --- PCIe ---
        # Active State Power Management for PCIe devices.
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersave";

        # --- Audio ---
        # Disable audio power saving on AC to prevent clicks.
        # Enable on battery.
        SOUND_POWER_SAVE_ON_AC = 1;
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # --- Battery Care ---
        # For ThinkPads and other supported models to prolong battery lifespan.
        # Uncomment and adjust values as needed.
        START_CHARGE_THRESH_BAT0 = 45;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        X11Forwarding = true;
        X11UseLocalhost = false; # Allows remote X connections
        PubkeyAuthentication = true;
      };
    };

    care = {
      enable = false;

      django = {
        allowedHosts = [ "localhost" ];
      };
      cors = {
        allowedOrigins = [ "https://example.com" ];
      };

      database = {
        createLocally = true; # Use external DB
      };
    };

    ####################
    # Display Manager  #
    ####################
    displayManager = {
      ly = {
        enable = true;
      };
    };

    ####################
    # Tailscale VPN    #
    ####################
    tailscale = {
      enable = true;
      authKeyFile = "/etc/tailscale/auth.key"; # path to your pre-auth key
      extraUpFlags = [
        "--accept-routes"
        "--advertise-exit-node"
        "--accept-dns=false"
      ];
      openFirewall = true;
    };

    ####################
    # Power Management  #
    ####################
    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "ignore";
          HandleLidSwitchExternalPower = "ignore";
        };
      };
    };

    nextcloud = {
      enable = true;
      hostName = "next.tellmey.tech";

      # Manually increment with every major upgrade.
      package = pkgs.nextcloud31;

      # Let NixOS install and configure the database automatically.
      database = {
        createLocally = true;
      };

      # Let NixOS install and configure Redis caching automatically.
      configureRedis = true;

      # Increase the maximum file upload size to avoid problems uploading videos.
      maxUploadSize = "16G";

      https = true;

      autoUpdateApps = {
        enable = true;
      };

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

    ####################
    # Cloudflare Tunnel#
    ####################
    cloudflared = {
      enable = true;
      tunnels = {
        "b0ca1206-1d09-4892-9d69-d3a196877013" = {
          credentialsFile = "/home/vysakh/.cloudflared/b0ca1206-1d09-4892-9d69-d3a196877013.json";
          default = "http_status:404";
          ingress = {
            "next.tellmey.tech" = { service = "http://localhost:80"; };
            "chat.tellmey.tech" = { service = "http://localhost:6167"; };
            "cal.tellmey.tech" = { service = "http://localhost:4000"; };
            "school.tellmey.tech" = { service = "http://localhost:7000"; };
          };
        };
      };
    };

    ####################
    # Maintenance      #
    ####################
    zfs = {
      trim = {
        enable = true;
      };
      autoScrub = {
        enable = true;
      };
    };
  };

  ####################
  virtualisation = {
    docker = {
      enable = true;
      extraPackages = with pkgs; [
        docker-buildx  # Explicitly include buildx
      ];
      daemon = {
        settings = {
          dns = [
            "8.8.8.8" # Google (works well in India)
            "1.1.1.1" # Cloudflare (fast in India)
            "208.67.222.222" # OpenDNS
            "9.9.9.9" # Quad9
          ];
        };
      };
    };
    podman = {
      enable = false;
      dockerCompat = true;
    };
  };

  # Provide Tailscale auth key from user home (ensure this file exists and is secured)
  environment = {
    etc = {
      "tailscale/auth.key" = {
        source = "/home/vysakh/tail.key";
      };
    };
  };

  networking = {
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
    resolvconf = {
      enable = true;
      # Override Tailscale DNS management
      extraConfig = ''
        name_servers="8.8.8.8 1.1.1.1"
      '';
    };

    # Trust the Tailscale interface (optional if openFirewall=true)
    firewall = {
      allowedUDPPorts = [ config.services.tailscale.port ];
      trustedInterfaces = [ "tailscale0" ];
      enable = true;
      allowedTCPPorts = [ 22 4000 80 443 ]; # SSH, HTTP, HTTPS
    };
  };

  ####################
  # User Programs    #
  ####################
  programs = {
    lazygit = {
      enable = true;
    };
    sway = {
      enable = true;
    };
    zsh = {
      enable = true;
      autosuggestions = {
        enable = true;
        async = true;
      };
      enableCompletion = true;
      syntaxHighlighting = {
        enable = true;
      };
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "python" "man" "direnv" "systemd" "docker-compose" "docker" "extract" "history" "battery" "timer" ];
        theme = "jonathan";
      };
      enableLsColors = true;
      enableGlobalCompInit = true;
    };
    direnv = {
      enable = true;
    };
    tmux = {
      enable = true;
    };
    bat = {
      enable = true;
    };
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
      flake = "/etc/nixos";
    };
    git = {
      enable = true;
      config = [
        { user.name = "Vysakh Premkumar"; }
        { user.email = "vysakhpr218@gmail.com"; }
      ];
    };
  };

  ####################
  # User Accounts    #
  ####################
  users = {
    users = {
      vysakh = {
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ "wheel" "docker" "networkmanager" ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEAAcrvQNZlE5PT9OhS6s7SH+gHCJB2sqIRo2mITwnER"
            ];
          };
        };
        packages = with pkgs; [ opentofu ];
      };
    };
  };

  # System packages are now defined in packages/chopper/system-packages.nix
}
