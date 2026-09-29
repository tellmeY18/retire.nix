{ pkgs
, config
, self
, lib
, ...
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
    ../../profiles/base.nix
    ../../packages/darwin
    ./defaults.nix

  ];
  system = {
    defaults = { };
    activationScripts = {
      # Runs before the `homebrew` activation script alphabetically.
      # Trusts 3rd-party taps so brew bundle doesn't refuse to load their casks.
      brewTrust = {
        text = ''
          echo "trusting 3rd-party brew taps..." >&2
          sudo -u mathewalex --set-home /opt/homebrew/bin/brew trust barutsrb/tap 2>/dev/null || true
        '';
      };
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
  environment.systemPackages = [
    pkgs.firefox-bin
    pkgs.tailscale
    self.inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Tailnet DNS needs BOTH halves below. They are complementary, not redundant
  # — removing either one breaks `ping chopper`, in two different ways:
  #
  #   1. accept-dns=true  → supplies the SEARCH DOMAIN (tail477f2f.ts.net), so
  #      the bare name "chopper" is expanded to chopper.tail477f2f.ts.net.
  #   2. /etc/resolver/…  → ROUTES that suffix to 100.100.100.100 (Tailscale's
  #      local MagicDNS proxy). Without it the expanded FQDN goes to 1.1.1.1,
  #      which returns NXDOMAIN for MagicDNS names.
  #
  # (2) is required because this tailnet pushes no resolvers — `tailscale dns
  # status` reports "Resolvers: (no resolvers configured, system default will
  # be used)" — so accept-dns alone never installs a 100.100.100.100 entry.
  # Verified: with only (1), `dig chopper.tail477f2f.ts.net` returns nothing
  # while `dig … @100.100.100.100` returns 100.107.213.17.
  #
  # Why not do the search domain with `networking.search`
  # (networksetup -setsearchdomains) instead of accept-dns: it applies, then
  # another network agent on this machine wipes it ~10-20s later (measured).
  # Tailscale's copy lives in the network extension, so it gets reapplied.
  # And why not put `search domain` in the /etc/resolver file: resolver(5)
  # scopes those files to *qualified* names and says `search` "is only used by
  # the Super DNS resolver", so it would be ignored there.
  environment.etc."resolver/tail477f2f.ts.net" = {
    text = ''
      nameserver 100.100.100.100
      timeout 5
    '';
  };

  # NB: this must live in `postActivation`, not a custom attribute name.
  # nix-darwin's activate script concatenates a fixed list of fragments
  # (preActivation, checks, …, networking, postActivation); an arbitrary
  # `system.activationScripts.<myName>` is silently never executed. The
  # previous `system.activationScripts.tailscaleAcceptDns` was dead code —
  # `/run/current-system/activate` contained no reference to it at all.
  #
  # accept-dns is a persisted tailscaled preference, so applying it once per
  # darwin-rebuild is enough — it survives reboots and Tailscale app restarts.
  system.activationScripts.postActivation.text = ''
    ts=/run/current-system/sw/bin/tailscale
    if [ -x "$ts" ] && "$ts" status >/dev/null 2>&1; then
      "$ts" set --accept-dns=true || true
    fi
  '';


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
      # macOS users are in `admin`, not `wheel`. The base config adds
      # `@wheel`, so we add `@admin` here to cover both platforms.
      trusted-users = lib.mkBefore [ "@admin" ];
      experimental-features = lib.mkAfter [ "ca-derivations" ];
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
