{
  description = "Unified flake: macOS (nix-darwin) + NixOS-on-ZFS (Disko)";

  ####################
  ##  Inputs
  ####################
  inputs = {
    # Single unstable channel for everything
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      # No extra inputs for nixpkgs
    };

    # macOS / Homebrew bits
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      # No extra inputs for nix-homebrew
    };

    # index database for nix-locate
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # My custom cook.nix
    #cook = {
    #  url = "github:tellmeY18/cook.nix";
    #  # No extra inputs for cook.nix
    #};

    # NixOS extras
    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
  ####################
  ##  Outputs
  ####################
  outputs =
    { self
    , nixpkgs
    , nix-darwin
      #    , cook
    , nix-homebrew
    , nix-index-database
    , nixvim
    , disko
    , sops-nix
    , ...
    }: {
      ############################################
      ##  Formatters (keep per-arch convenience)
      ############################################
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      };

      ############################################
      ##  macOS – Vysakh’s MacBook Pro
      ############################################
      darwinConfigurations."Vysakhs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          # expose flake-self inside modules
          ({ ... }: { _module.args.self = self; })

          ./hosts/darwin/configuration.nix

          # upstream modules
          nix-homebrew.darwinModules.nix-homebrew
          nixvim.nixDarwinModules.nixvim
          nix-index-database.darwinModules.nix-index

          # local tweaks
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "mathewalex";
              autoMigrate = true;
            };
          }
        ];
      };

      # Handy package set alias
      darwinPackages =
        self.darwinConfigurations."Vysakhs-MacBook-Pro".pkgs;

      ############################################
      ##  NixOS – “chopper” host on ZFS + Disko
      ############################################
      nixosConfigurations.chopper = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            nixpkgs.overlays = [
              (final: prev: {
                postgresql_16_neon = final.callPackage ./packages/neondb/postgresql-neon.nix {};
                neondb = final.callPackage ./packages/neondb/default.nix {
                  postgresql_14 = final.postgresql_14;
                  postgresql_15 = final.postgresql_15;
                  postgresql_16 = final.postgresql_16_neon;
                };
              })
            ];
          }
          ./hosts/chopper/configuration.nix
          ./hosts/chopper/hardware-configuration.nix
          ./hosts/chopper/disko-config.nix
          #cook.nixosModules.default
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
        ];
      };
    };
}
