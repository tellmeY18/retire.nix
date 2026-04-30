# nix-config task runner
# Run 'just' to list available commands.

# List available commands
default:
    @just --list

# Format all files with treefmt
fmt:
    treefmt

# Run nix flake check
check:
    nix flake check

# Run statix and deadnix linters
lint:
    statix check .
    deadnix .

# Build chopper NixOS configuration
build-chopper:
    nix build .#nixosConfigurations.chopper.config.system.build.toplevel

# Build macOS (darwin) configuration
build-mac:
    nix build .#darwinConfigurations.Vysakhs-MacBook-Pro.system

# Build Home Manager config for mac
build-home-mac:
    nix build .#homeConfigurations."mathewalex@Vysakhs-MacBook-Pro".activationPackage

# Build Home Manager config for chopper
build-home-chopper:
    nix build .#homeConfigurations."vysakh@chopper".activationPackage

# Build all configurations
build-all: build-chopper build-mac build-home-mac build-home-chopper

# Deploy to a specific NixOS host (e.g., just deploy chopper)
deploy host:
    deploy .#{{host}}

# Deploy to all configured hosts
deploy-all:
    deploy .

# Dry-run deploy (build + dry-activate, no switch)
deploy-dry host:
    deploy .#{{host}} -- --dry-activate

# Collect garbage and delete old generations
clean:
    nix-collect-garbage -d
