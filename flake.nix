{
  description = "Unified flake: macOS (nix-darwin) + NixOS-on-ZFS (Disko)";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      # Intentionally NOT following nixpkgs — nixvim manages its own
      # plugin builds against its tested nixpkgs pin. Using `follows`
      # triggers a version-mismatch warning with no real benefit.
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned nixpkgs commit that ships signal-cli 0.14.5 (fixes NPE on inbound
    # messages where server omits serverGuid from sealed-sender envelopes).
    # Used only for pkgs.signal-cli via the custom-packages overlay.
    nixpkgs-signal.url = "github:NixOS/nixpkgs/c6e1d1e0eebf3a5338abc4bde24e4e88d58a6f01";
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      # Intentionally NOT following nixpkgs — lets the upstream flake use its
      # own pinned revision so Garnix binary cache hits. Following our unstable
      # nixpkgs would change every derivation hash and defeat caching.
    };
  };

  outputs =
    inputs@{
      self,
      nix-homebrew,
      nix-index-database,
      nixvim,
      fenix,
      disko,
      sops-nix,
      deploy-rs,
      emacs-overlay,
      ...
    }:
    let
      myLib = import ./lib { inherit inputs; };
    in
    {
      ## Overlays — importable by downstream flakes
      overlays = import ./overlays { inherit inputs; };

      ## Per-system outputs
      formatter = myLib.forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);

      packages = myLib.forAllSystems (
        { pkgs, system, ... }:
        {
          default = fenix.packages.${system}.minimal.toolchain;
          # Expose deploy-rs so `nix run .#deploy-rs` works outside the devshell.
          # Used by the Justfile `deploy` / `deploy-dry` recipes.
          deploy-rs = deploy-rs.packages.${system}.default;
          # Tailscale-aware kexec tarball for nixos-anywhere.
          # Build: nix build .#packages.<system>.kexec-image
          kexec-image = pkgs.callPackage ./packages/kexec-image.nix { };
        }
      );

      devShells = myLib.forAllSystems (
        { pkgs, system, ... }:
        let
          chromiumPath =
            if pkgs.stdenv.isDarwin then
              "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            else
              "${pkgs.chromium}/bin/chromium";
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixpkgs-fmt
              pkgs.statix
              pkgs.deadnix
              pkgs.nil
              pkgs.sops
              pkgs.age
              pkgs.just
              pkgs.treefmt
              pkgs.presenterm
              pkgs.mermaid-cli # provides `mmdc` for presenterm mermaid rendering
              deploy-rs.packages.${system}.default
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.chromium ];
            shellHook = ''
              export PUPPETEER_EXECUTABLE_PATH="${chromiumPath}"
              git config core.hooksPath .githooks
              echo "nix-config devshell ready — run 'just' for available commands"
            '';
          };
        }
      );

      ## ── Auto-discovered host configurations ──────────────────────────
      #  Adding a new host = mkdir hosts/<name>, drop metadata.nix +
      #  configuration.nix, and (optionally) add extraModules below.
      #  No other flake.nix edits required.

      ## macOS hosts (nix-darwin)
      darwinConfigurations = myLib.mkDarwinConfigurations {
        hostsDir = ./hosts;
        extraModules = {
          darwin = [
            nix-homebrew.darwinModules.nix-homebrew
            nix-index-database.darwinModules.nix-index
            {
              nixpkgs.overlays = [
                fenix.overlays.default
                self.overlays.custom-packages
                emacs-overlay.overlays.default
              ];
            }
            ./modules/dev/rust.nix
            ./hosts/darwin/homebrew.nix
          ];
        };
      };

      darwinPackages = self.darwinConfigurations."Vysakhs-MacBook-Pro".pkgs;

      ## NixOS hosts
      nixosConfigurations = myLib.mkNixosConfigurations {
        hostsDir = ./hosts;
        extraModules = {
          chopper = [
            {
              nixpkgs.overlays = [
                self.overlays.custom-packages
              ];
            }
            ./hosts/chopper/hardware-configuration.nix
            ./hosts/chopper/disko-config.nix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            inputs.nix-openclaw.nixosModules.openclaw-gateway
            # Force openclaw-gateway from the nix-openclaw flake's own nixpkgs
            # pin so Garnix binary cache hits. The nixpkgs-unstable version of
            # openclaw (2026.6.5) has to build its pnpm deps from source (~1GB)
            # and times out over SSH-remote-build.
            # Also expose the official signal runtime plugin so the gateway can
            # load it declaratively via plugins.load.paths.
            ({ lib, ... }: {
              _module.args = {
                openclaw-signal-plugin = inputs.nix-openclaw.packages.x86_64-linux."openclaw-runtime-plugin-signal";
              };
              services.openclaw-gateway.package = lib.mkForce inputs.nix-openclaw.packages.x86_64-linux.openclaw-gateway;
            })
          ];
          kenobi = [
            ./hosts/kenobi/disko-config.nix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
          c3po = [
            ./hosts/c3po/disko-config.nix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
          r2d2 = [
            ./hosts/r2d2/disko-config.nix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
          # yoda — phase 2: sops-nix (Tailscale auth key + k3s join token),
          # Tailscale, and the k3s compute agent are now wired in.
          yoda = [
            ./hosts/yoda/disko-config.nix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
      };

      ## Home Manager Standalone Configurations
      # TODO(milestone-5): auto-discover home configs from hosts/*/metadata.nix users.
      homeConfigurations = {
        "mathewalex@Vysakhs-MacBook-Pro" = myLib.mkHome {
          system = "aarch64-darwin";
          modules = [
            # Expose the flake `self` to home-manager modules so they can
            # reference paths relative to the repository root (e.g. skills).
            ({ ... }: { _module.args.self = self; })
            nixvim.homeModules.nixvim
            ./home/darwin-home.nix
          ];
        };
      };

      ## ── deploy-rs ────────────────────────────────────────────────────
      deploy.nodes = myLib.mkDeployNodes {
        hostsDir = ./hosts;
        nixosConfigurations = self.nixosConfigurations;
        deployLib = deploy-rs.lib;
      };

      ## ── Flake checks (includes deploy-rs validation) ─────────────────
      checks = myLib.forAllSystems ({ system, ... }: deploy-rs.lib.${system}.deployChecks self.deploy);
    };
}
