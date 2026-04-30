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
    nix run .#deploy-rs -- .#{{host}}

# Deploy to all configured hosts
deploy-all:
    nix run .#deploy-rs -- .#

# Dry-run deploy (build + dry-activate, no switch)
deploy-dry host:
    nix run .#deploy-rs -- .#{{host}} -- --dry-activate

# Collect garbage and delete old generations
clean:
    nix-collect-garbage -d

# ---------------------------------------------------------------------------
# Kubernetes / k8s recipes
# ---------------------------------------------------------------------------

# Apply all k8s cluster resources (helmfile + kustomize + sops secrets)
k8s-apply:
    helmfile sync --file k8s/helmfile.yaml
    kubectl apply -k k8s/clusters/chopper
    @echo "Applying sops-encrypted secrets..."
    for f in k8s/clusters/chopper/secrets/*.enc.yaml; do sops --decrypt "$f" | kubectl apply -f -; done

# Preview k8s changes without applying
k8s-diff:
    helmfile diff --file k8s/helmfile.yaml
    kubectl diff -k k8s/clusters/chopper

# Edit a sops-encrypted secret file  (e.g. just k8s-edit-secret k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml)
k8s-edit-secret path:
    sops {{path}}
