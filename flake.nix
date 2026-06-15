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
    nix-darwin-aerohud = {
      url = "github:tellmeY18/nix-darwin/1b5caa6f694856ad74d601e6e07fcefd738add2d";
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
      nix-darwin-aerohud,
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
        { system, ... }:
        {
          default = fenix.packages.${system}.minimal.toolchain;
          # Expose deploy-rs so `nix run .#deploy-rs` works outside the devshell.
          # Used by the Justfile `deploy` / `deploy-dry` recipes.
          deploy-rs = deploy-rs.packages.${system}.default;
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
                nix-darwin-aerohud.overlays.default
              ];
            }
            # aerohud module from the nix-darwin fork (tellmeY18)
            "${nix-darwin-aerohud}/modules/services/aerohud"
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
        };
      };

      ## Home Manager Standalone Configurations
      # TODO(milestone-5): auto-discover home configs from hosts/*/metadata.nix users.
      homeConfigurations = {
        "mathewalex@Vysakhs-MacBook-Pro" = myLib.mkHome {
          system = "aarch64-darwin";
          modules = [
            nixvim.homeModules.nixvim
            ./home/darwin-home.nix
          ];
        };

        "vysakh@chopper" = myLib.mkHome {
          system = "x86_64-linux";
          modules = [
            nixvim.homeModules.nixvim
            ./home/linux-home.nix
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
