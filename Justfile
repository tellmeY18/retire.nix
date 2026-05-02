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

# Apply all k8s cluster resources (helmfile + kustomize + sops secrets).
# Order matters:
#   1. helmfile installs/upgrades the CNPG operator (and its CRDs) first.
#      The Cluster CR in step 2 will fail apply if the CRD is not yet present.
#   2. kustomize applies the namespace, network policies, Cluster, Pooler,
#      ScheduledBackup, and Tailscale Service.
#   3. sops decrypts each *.enc.yaml secret and pipes it into kubectl apply.
#      The for-loop uses `nullglob` so a missing /empty secrets dir is a
#      no-op rather than an error (the literal pattern would otherwise be
#      passed to sops verbatim).
k8s-apply:
    helmfile sync --file k8s/helmfile.yaml
    kubectl apply -k k8s/clusters/chopper
    @echo "Applying sops-encrypted secrets..."
    @bash -c 'shopt -s nullglob; for f in k8s/clusters/chopper/secrets/*.enc.yaml; do echo "  $f"; sops --decrypt "$f" | kubectl apply -f -; done'

# Preview k8s changes without applying.
k8s-diff:
    helmfile diff --file k8s/helmfile.yaml
    kubectl diff -k k8s/clusters/chopper || true

# Edit a sops-encrypted secret file.
# Example:
#   just k8s-edit-secret k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml
k8s-edit-secret path:
    sops {{path}}

# Show the CNPG cluster status (uses the kubectl-cnpg plugin).
# Install the plugin once with:
#   kubectl krew install cnpg
k8s-cnpg-status:
    kubectl cnpg status chopper-pg -n cnpg-clusters

# Tail logs from the CNPG operator.
k8s-cnpg-operator-logs:
    kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg -f --tail=200

# Tail logs from the current CNPG primary.
k8s-cnpg-primary-logs:
    kubectl logs -n cnpg-clusters -l cnpg.io/cluster=chopper-pg,role=primary -f --tail=200

# Trigger an on-demand backup.
k8s-cnpg-backup-now:
    kubectl cnpg backup chopper-pg -n cnpg-clusters

# List Backup objects with their phase.
k8s-cnpg-backup-list:
    kubectl get backup -n cnpg-clusters -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,STARTED:.status.startedAt,STOPPED:.status.stoppedAt
