{
  description = "Unified flake: macOS (nix-darwin) + NixOS-on-ZFS (Disko)";

  inputs = {
    # Channel strategy:
    #   - nixpkgs (unstable): default for most packages — latest features
    #   - nixpkgs-stable (25.11): pinned for services that need stability
    #     (Nextcloud, PostgreSQL, etc.) — see docs/channels.md
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };
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
      overlays = import ./overlays;

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
                (import ./overlays).custom-packages
              ];
            }
            ./hosts/chopper/hardware-configuration.nix
            ./hosts/chopper/disko-config.nix
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
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
          # yoda — phase 1 (bootstrap): disko only. sops-nix is added in
          # phase 2 alongside Tailscale + k3s once secrets exist.
          yoda = [
            ./hosts/yoda/disko-config.nix
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
