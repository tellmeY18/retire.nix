# nix-config task runner
# Run 'just' to list top-level recipes.
# Run 'just k8s' to list k8s sub-recipes (or `just k8s::<recipe>`).

# List available commands
default:
    @just --list

# ---------------------------------------------------------------------------
# Sub-modules
# ---------------------------------------------------------------------------
# k8s/Justfile owns every kubectl/helmfile/sops recipe. Recipes are run
# with `k8s/` as their working directory so helm-secrets `secrets://`
# URLs resolve correctly. Invoke as either:
#   just k8s                  list sub-recipes
#   just k8s::apply           run the k8s apply recipe
#   (cd k8s && just apply)    equivalent
[doc('k8s recipes (helmfile / kubectl / sops). `just k8s` to list')]
mod k8s 'k8s/Justfile'

# ---------------------------------------------------------------------------
# Repo-wide recipes
# ---------------------------------------------------------------------------

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
    nix run .#deploy-rs -- .#{{ host }}

# Deploy to all configured hosts
deploy-all:
    nix run .#deploy-rs -- .#

# Dry-run deploy (build + dry-activate, no switch)
deploy-dry host:
    nix run .#deploy-rs -- .#{{ host }} -- --dry-activate

# Collect garbage and delete old generations
clean:
    nix-collect-garbage -d
