# lib/default.nix — Thin helpers that keep flake.nix small.
# Import with: myLib = import ./lib { inherit inputs; };
{ inputs }:

let
  inherit (inputs.nixpkgs) lib;

  supportedSystems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  # ---------------------------------------------------------------------------
  # Per-system iterator
  # ---------------------------------------------------------------------------

  # Iterate a function over every supported system.
  # `f` receives { system, pkgs }.
  forAllSystems =
    f:
    lib.genAttrs supportedSystems (
      system:
      f {
        inherit system;
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      }
    );

  # ---------------------------------------------------------------------------
  # Low-level host factories (caller supplies all modules)
  # ---------------------------------------------------------------------------

  # NixOS host factory — caller supplies all modules.
  mkHost =
    {
      system,
      modules ? [ ],
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = modules;
    };

  # nix-darwin host factory — injects `self` into module args automatically.
  mkDarwinHost =
    {
      system ? "aarch64-darwin",
      modules ? [ ],
    }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        (
          { ... }:
          {
            _module.args.self = inputs.self;
          }
        )
      ]
      ++ modules;
    };

  # ---------------------------------------------------------------------------
  # Host auto-discovery
  # ---------------------------------------------------------------------------

  # Scan a hosts directory and return { dirName = <metadata>; ... } for every
  # subdirectory that contains both metadata.nix and configuration.nix.
  # The "template" directory is explicitly skipped.
  discoverHosts =
    hostsDir:
    let
      entries = builtins.readDir hostsDir;
      hostDirs = lib.filterAttrs (name: type: type == "directory" && name != "template") entries;
      withMetadata = lib.filterAttrs (
        name: _:
        builtins.pathExists (hostsDir + "/${name}/metadata.nix")
        && builtins.pathExists (hostsDir + "/${name}/configuration.nix")
      ) hostDirs;
      loadHost = name: _: import (hostsDir + "/${name}/metadata.nix");
    in
    lib.mapAttrs loadHost withMetadata;

  # Build all NixOS configurations from discovered hosts.
  # Keys are meta.hostname (e.g. "chopper"), not the directory name.
  # extraModules is keyed by *directory name* so callers don't need to know
  # the hostname — only the directory they created.
  mkNixosConfigurations =
    {
      hostsDir,
      extraModules ? { },
    }:
    let
      allHosts = discoverHosts hostsDir;
      nixosHosts = lib.filterAttrs (_: meta: meta.type == "nixos") allHosts;
    in
    lib.mapAttrs' (
      dirName: meta:
      lib.nameValuePair meta.hostname (mkHost {
        system = meta.system;
        modules = [
          (hostsDir + "/${dirName}/configuration.nix")
        ]
        ++ (extraModules.${dirName} or [ ]);
      })
    ) nixosHosts;

  # Build all Darwin configurations from discovered hosts.
  # Same hostname-keying and dirName-based extraModules as above.
  mkDarwinConfigurations =
    {
      hostsDir,
      extraModules ? { },
    }:
    let
      allHosts = discoverHosts hostsDir;
      darwinHosts = lib.filterAttrs (_: meta: meta.type == "darwin") allHosts;
    in
    lib.mapAttrs' (
      dirName: meta:
      lib.nameValuePair meta.hostname (mkDarwinHost {
        system = meta.system;
        modules = [
          (hostsDir + "/${dirName}/configuration.nix")
        ]
        ++ (extraModules.${dirName} or [ ]);
      })
    ) darwinHosts;

  # ---------------------------------------------------------------------------
  # deploy-rs node generation
  # ---------------------------------------------------------------------------

  # Build deploy-rs nodes from discovered hosts that have deploy metadata.
  # Only NixOS hosts are supported (darwin doesn't use deploy-rs).
  #
  # Usage in flake.nix:
  #   deploy.nodes = myLib.mkDeployNodes {
  #     hostsDir = ./hosts;
  #     nixosConfigurations = self.nixosConfigurations;
  #     deployLib = deploy-rs.lib;
  #   };
  mkDeployNodes =
    {
      hostsDir,
      nixosConfigurations,
      deployLib,
    }:
    let
      allHosts = discoverHosts hostsDir;
      deployableHosts = lib.filterAttrs (_: meta: meta.type == "nixos" && meta ? deploy) allHosts;
    in
    lib.mapAttrs' (
      dirName: meta:
      lib.nameValuePair meta.hostname {
        hostname = meta.deploy.host;
        sshUser = meta.deploy.sshUser or "root";
        remoteBuild = meta.deploy.remoteBuild or true;

        profiles.system = {
          user = "root";
          path = deployLib.${meta.system}.activate.nixos nixosConfigurations.${meta.hostname};
        };
      }
    ) deployableHosts;

  # ---------------------------------------------------------------------------
  # Standalone Home Manager factory
  # ---------------------------------------------------------------------------

  mkHome =
    {
      system,
      modules ? [ ],
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      modules = modules;
    };

in
{
  inherit
    supportedSystems
    forAllSystems
    mkHost
    mkDarwinHost
    discoverHosts
    mkNixosConfigurations
    mkDarwinConfigurations
    mkDeployNodes
    mkHome
    ;
}
