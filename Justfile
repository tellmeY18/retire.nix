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

# Apply all k8s cluster resources (helmfile + kustomize).
# Order matters:
#   1. helmfile installs/upgrades the CNPG operator (and its CRDs) first.
#      The cnpg/cluster release in step 1 (declared via `needs:`) waits
#      for the operator to be ready before applying the Cluster CR.
#   2. kustomize applies the namespace, network policies, and Tailscale
#      LoadBalancer Service.
#
# Helm-side secrets (S3 access keys for backups) live in
# k8s/apps/postgres/secrets.yaml as a sops-encrypted helm values file and
# are merged in by helm-secrets at install time — we no longer need a
# separate sops --decrypt | kubectl apply step.
k8s-apply:
    helmfile sync --file k8s/helmfile.yaml
    kubectl apply -k k8s/clusters/glug-infra

# Preview k8s changes without applying.
k8s-diff:
    helmfile diff --file k8s/helmfile.yaml
    kubectl diff -k k8s/clusters/glug-infra || true

# Edit a sops-encrypted secret file.
# Examples:
#   just k8s-edit-secret k8s/apps/postgres/secrets.yaml
#   just k8s-edit-secret k8s/apps/cnpg-operator/secrets.yaml
k8s-edit-secret path:
    sops {{path}}

# Show the CNPG cluster status (uses the kubectl-cnpg plugin).
# Install the plugin once with:
#   kubectl krew install cnpg
k8s-cnpg-status:
    kubectl cnpg status postgres -n cnpg-clusters

# Tail logs from the CNPG operator.
k8s-cnpg-operator-logs:
    kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg -f --tail=200

# Tail logs from the current CNPG primary.
k8s-cnpg-primary-logs:
    kubectl logs -n cnpg-clusters -l cnpg.io/cluster=postgres,role=primary -f --tail=200

# Trigger an on-demand backup.
k8s-cnpg-backup-now:
    kubectl cnpg backup postgres -n cnpg-clusters

# List Backup objects with their phase.
k8s-cnpg-backup-list:
    kubectl get backup -n cnpg-clusters -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,STARTED:.status.startedAt,STOPPED:.status.stoppedAt
