{
  pkgs,
  config,
  self,
  lib,
  ...
}:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    hostPlatform = "aarch64-darwin";
  };
  # Import system packages
  imports = [
    ../../packages/darwin
    ./programs.nix
    ./services.nix
    ./sketchybar
  ];
  system = {
    defaults = {
      loginwindow = {
        LoginwindowText = "Declare Nix ! Not War";
      };

    };
    activationScripts = {
      applications = {
        text =
          let
            env = pkgs.buildEnv {
              name = "system-applications";
              paths = config.environment.systemPackages;
              pathsToLink = [ "/Applications" ];
            };
          in
          pkgs.lib.mkForce ''
            # Set up applications.
            echo "setting up /Applications..." >&2
            rm -rf /Applications/Nix\ Apps
            mkdir -p /Applications/Nix\ Apps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              # Add Spotlight indexing for Nix Apps
              mdimport "/Applications/Nix Apps/$app_name"
            done
          '';
      };
    };
    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;
    # Set primary user for Homebrew and other user-specific options
    primaryUser = "mathewalex";
    # Used for backwards compatibility
    stateVersion = 5;
  };

  # Fonts — Nerd Fonts for sketchybar icons + terminal ligatures.
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # Tailscale CLI — lets `tailscale` work in terminals while the macOS
  # Tailscale app (system extension) owns the actual tunnel + DNS injection.
  # Do NOT enable services.tailscale here; see services.nix for the rationale.
  environment.systemPackages = [ pkgs.tailscale ];

  # MagicDNS resolver — macOS /etc/resolver/<domain> files are loaded by
  # mDNSResponder at startup and take precedence over scutil entries injected
  # later by VPN apps.  Without this, the Tailscale app (when its admin-console
  # nameserver is set to 1.1.1.1) pushes 1.1.1.1 as the resolver for the
  # tail477f2f.ts.net supplemental entry, which can't resolve MagicDNS names.
  # 100.100.100.100 is Tailscale's local DNS proxy — reachable only while
  # connected; macOS falls back to the system resolver when it's unreachable.
  environment.etc."resolver/tail477f2f.ts.net" = {
    text = ''
      nameserver 100.100.100.100
      timeout 5
    '';
  };

  # Tell the Tailscale daemon to stop managing system DNS.
  # When accept-dns=true (the default), the macOS Tailscale app injects scutil
  # supplemental resolvers at order 100800 — higher priority than any
  # /etc/resolver/ file.  If the admin-console global nameserver is set to
  # 1.1.1.1 those entries route *.tail477f2f.ts.net to Cloudflare, which
  # cannot answer MagicDNS queries.  Disabling accept-dns hands DNS fully
  # back to the OS; our /etc/resolver file above then handles the tailnet
  # zone via 100.100.100.100 (Tailscale's local proxy, always reachable when
  # the tunnel is up).
  #
  # The activation script is not enough — it only runs during darwin-rebuild.
  # The LaunchAgent ensures this also runs on every login/boot *after* the
  # Tailscale socket appears, surviving Tailscale app restarts.
  system.activationScripts.tailscaleAcceptDns = {
    text = ''
      # Clean up old launch agent label (renamed to tailscaleDns)
      launchctl remove org.nixos.tailscaleAcceptDns 2>/dev/null || true

      ts=/run/current-system/sw/bin/tailscale
      if [ -x "$ts" ] && "$ts" status >/dev/null 2>&1; then
        "$ts" set --accept-dns=false || true
      fi
    '';
  };

  # LaunchAgent — fixes DNS on every login:
  #   1. Disables Tailscale accept-dns (it conflicts with /etc/resolver)
  #   2. Adds the tailnet search domain so bare hostnames resolve
  #      (e.g. "chopper" → chopper.tail477f2f.ts.net)
  launchd.user.agents.tailscaleDns = {
    script = ''
      # Clean up old agent label (renamed from tailscaleAcceptDns)
      launchctl remove org.nixos.tailscaleAcceptDns 2>/dev/null || true

      # Wait up to 30s for the Tailscale socket
      for i in $(seq 30); do
        if [ -S /var/run/tailscale/tailscaled.sock ]; then break; fi
        sleep 1
      done

      TS=${pkgs.tailscale}/bin/tailscale
      if [ -x "$TS" ] && "$TS" status >/dev/null 2>&1; then
        # 1. Stop Tailscale from managing DNS (conflicts with /etc/resolver)
        "$TS" set --accept-dns=false 2>/dev/null || true

        # 2. Add search domain so bare hostnames resolve via MagicDNS
        #    e.g. "ping chopper" → chopper.tail477f2f.ts.net
        SEARCH="tail477f2f.ts.net"
        for svc in "Wi-Fi" "Thunderbolt Bridge" "Ethernet"; do
          CURRENT=$(networksetup -getsearchdomains "$svc" 2>/dev/null) || continue
          echo "$CURRENT" | grep -qF "$SEARCH" || {
            if [ -z "$CURRENT" ]; then
              networksetup -setsearchdomains "$svc" "$SEARCH" 2>/dev/null || true
            else
              networksetup -setsearchdomains "$svc" "$CURRENT" "$SEARCH" 2>/dev/null || true
            fi
          }
          break
        done
      fi
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/tailscaleDns.log";
      StandardErrorPath = "/tmp/tailscaleDns.log";
    };
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        # Use MagicDNS name so this works regardless of IP reassignment.
        # Resolved via /etc/resolver/tail477f2f.ts.net → 100.100.100.100.
        hostName = "chopper.tail477f2f.ts.net";
        sshUser = "vysakh";
        systems = [ "x86_64-linux" ];
      }
    ];
    linux-builder = {
      enable = true;
    };
    # These are the global Nix settings. Community caches are merged with
    # the binary-cache module via mkAfter to ensure graceful fallback.
    settings = {
      # Append community caches after binary-cache module defaults
      substituters = lib.mkAfter [
        "https://tellmey18.cachix.org"
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
        "https://deploy-rs.cachix.org"
        "https://tranquil.cachix.org"
      ];
      trusted-public-keys = lib.mkAfter [
        "tellmey18.cachix.org-1:udK9FzY4ZOHz4OapcTUHkwb/b10+5eQzCi44ZA6oFLw="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
        "tranquil.cachix.org-1:PoO+mGL6a6LcJiPakMDHN4E218/ei/7v2sxeDtNkSRg="
      ];
      experimental-features = "nix-command flakes ca-derivations";
    };
  };
  # Enable Touch ID for sudo authentication.
  security = {
    pam = {
      services = {
        sudo_local = {
          touchIdAuth = true;
        };
      };
    };
  };
}
