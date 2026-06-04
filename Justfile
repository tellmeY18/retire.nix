# nix-config — infrastructure task runner

#
# This repo is the SINGLE SOURCE OF TRUTH for all NixOS infrastructure.
# The Mac is the only admin workstation. deploy-rs pushes configs to all
# NixOS nodes. No SSH'ing into servers to run commands.
#
# Workflow:
#   1. Edit nix configs locally
#   2. `just check` — lint + evaluate
#   3. `just deploy <host>` or `just deploy-all` — push to infra
#   4. `just k8s::apply` — sync k8s manifests
#
# Run 'just' to list all recipes.

# List available commands
default:
    @just --list --unsorted

# ---------------------------------------------------------------------------
# Sub-modules
# ---------------------------------------------------------------------------

[doc('k8s recipes (helmfile / kubectl / sops). `just k8s` to list')]
mod k8s 'k8s/Justfile'

# ═══════════════════════════════════════════════════════════════════════════
#  PRESENT — launch slides in a presentation-tuned terminal
# ═══════════════════════════════════════════════════════════════════════════

# Launch presenterm inside kitty with a large, presentation-friendly font.
[doc('Present slides (kitty + Iosevka 22pt)')]
present:
    kitty --config KochiFoss/kitty-present.conf presenterm -x KochiFoss/Slides.md

# ═══════════════════════════════════════════════════════════════════════════
#  DEPLOY — push NixOS configs to remote hosts via deploy-rs
# ═══════════════════════════════════════════════════════════════════════════
#
# deploy-rs builds on the REMOTE host (remoteBuild = true in metadata.nix)
# so there's no cross-compilation from the Mac. The Mac only evaluates the
# flake and copies derivation sources over Tailscale.
#
# Hosts:
#   chopper   x86_64-linux   k3s server-init (etcd + apiserver)
#   kenobi    aarch64-linux  k3s agent (compute node, OCI ARM VM)

# Deploy to a specific NixOS host.
#
# --magic-rollback false is REQUIRED for the k3s nodes (chopper/c3po/kenobi):
# their networking blips during activation, so the magic-rollback confirmation
# round-trip fails and triggers a rollback that churns k3s/etcd. See the
# deploy-k3s-nodes skill.
[doc('Deploy NixOS config to a host (e.g. just deploy chopper)')]
deploy host:
    nix run .#deploy-rs -- .#{{ host }} --skip-checks --magic-rollback false

# Deploy to ALL configured NixOS hosts.
#
# DANGER for the k3s cluster: this bounces all three control-plane/etcd nodes
# in one run, which risks quorum. Prefer `just deploy <host>` ONE AT A TIME,
# verifying each node rejoins (see the deploy-k3s-nodes skill) before the next.
[doc('Deploy NixOS config to all hosts (avoid for the k3s nodes — see skill)')]
deploy-all:
    nix run .#deploy-rs -- --skip-checks --magic-rollback false

# Dry-run: build + dry-activate without switching.
[doc('Dry-run deploy (build only, no switch)')]
deploy-dry host:
    nix run .#deploy-rs -- .#{{ host }} --skip-checks --dry-activate

# ═══════════════════════════════════════════════════════════════════════════
#  BUILD — evaluate / build configs locally (no deploy)
# ═══════════════════════════════════════════════════════════════════════════

# Evaluate a NixOS host config (fast — no build, just check for errors).
[doc('Evaluate a NixOS config without building (e.g. just eval chopper)')]
eval host:
    nix eval .#nixosConfigurations.{{ host }}.config.system.build.toplevel.drvPath

# Evaluate ALL NixOS hosts.
[doc('Evaluate all NixOS configs')]
eval-all:
    #!/usr/bin/env bash
    set -euo pipefail
    for host in chopper kenobi; do
      echo "Evaluating $host..."
      nix eval .#nixosConfigurations.$host.config.system.build.toplevel.drvPath
      echo "  ✓ $host OK"
    done

# Build chopper NixOS configuration (local eval, remote would build).
[doc('Build chopper NixOS config')]
build-chopper:
    nix build .#nixosConfigurations.chopper.config.system.build.toplevel

# Build kenobi NixOS configuration (aarch64-linux).
[doc('Build kenobi NixOS config')]
build-kenobi:
    nix build .#nixosConfigurations.kenobi.config.system.build.toplevel

# Build macOS (darwin) configuration.
[doc('Build macOS darwin config')]
build-mac:
    nix build .#darwinConfigurations.Vysakhs-MacBook-Pro.system

# Build Home Manager config for Mac.
[doc('Build Home Manager for Mac')]
build-home-mac:
    nix build .#homeConfigurations."mathewalex@Vysakhs-MacBook-Pro".activationPackage

# Build Home Manager config for chopper.
[doc('Build Home Manager for chopper')]
build-home-chopper:
    nix build .#homeConfigurations."vysakh@chopper".activationPackage

# Build all configurations.
[doc('Build everything (all hosts + HM)')]
build-all: build-chopper build-kenobi build-mac build-home-mac build-home-chopper

# ═══════════════════════════════════════════════════════════════════════════
#  LINT / CHECK — code quality
# ═══════════════════════════════════════════════════════════════════════════

# Format all files with treefmt.
[doc('Format all files')]
fmt:
    treefmt

# Run nix flake check (includes deploy-rs validation).
[doc('Run nix flake check')]
check:
    nix flake check

# Run statix and deadnix linters.
[doc('Run nix linters (statix + deadnix)')]
lint:
    statix check .
    deadnix .

# Full pre-deploy validation: lint + eval all hosts.
[doc('Full validation: lint + eval all hosts')]
validate: lint eval-all
    @echo "✓ All checks passed"

# ═══════════════════════════════════════════════════════════════════════════
#  SECRETS — sops-nix
# ═══════════════════════════════════════════════════════════════════════════

# Edit a host's sops secrets file.
[doc('Edit sops secrets for a host (e.g. just secrets chopper)')]
secrets host:
    sops secrets/{{ host }}/secrets.yaml

# ═══════════════════════════════════════════════════════════════════════════
#  KUBECONFIG — control plane access via Tailscale
# ═══════════════════════════════════════════════════════════════════════════

# Fetch kubeconfig from chopper, rewrite server URL to use the stable
# Tailscale LB endpoint (k3s-cp.tail477f2f.ts.net). This kubeconfig
# works from any device on the tailnet.
[doc('Fetch kubeconfig via Tailscale LB endpoint')]
fetch-kubeconfig:
    #!/usr/bin/env bash
    set -euo pipefail
    REMOTE="root@100.107.213.17"
    REMOTE_PATH="/etc/rancher/k3s/k3s.yaml"
    LOCAL="${HOME}/.kube/glug-infra.yaml"
    mkdir -p "${HOME}/.kube"
    echo "Fetching kubeconfig from chopper..."
    scp "${REMOTE}:${REMOTE_PATH}" "${LOCAL}"
    # Rewrite to use the stable Tailscale LB endpoint.
    sed -i'' -e 's|https://127.0.0.1:6443|https://k3s-cp.tail477f2f.ts.net:6443|g' "${LOCAL}"
    chmod 600 "${LOCAL}"
    echo "✓ Kubeconfig saved to ${LOCAL}"
    echo "  Server: https://k3s-cp.tail477f2f.ts.net:6443"
    echo "  Usage:  export KUBECONFIG=${LOCAL}"

# Regenerate k3s API server TLS certs (after adding new SANs).
# This deletes the old serving certs and restarts k3s, which
# regenerates them with the current --tls-san flags.
[doc('Regenerate k3s API server certs with current SANs')]
regen-certs:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Deleting old API server certs on chopper..."
    ssh root@100.107.213.17 'rm -f /var/lib/rancher/k3s/server/tls/serving-kube-apiserver.crt /var/lib/rancher/k3s/server/tls/serving-kube-apiserver.key && systemctl restart k3s'
    echo "✓ Certs regenerated. k3s restarted."
    echo "  Wait ~15s for the API server to come back, then run:"
    echo "    just fetch-kubeconfig"

# ═══════════════════════════════════════════════════════════════════════════
#  REMOTE — SSH into hosts (emergency use only)
# ═══════════════════════════════════════════════════════════════════════════

# SSH into a host via Tailscale. Emergency use only — prefer deploy-rs.
[doc('SSH into a host (emergency use only)')]
ssh host:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ host }}" in
      chopper) ssh root@100.107.213.17 ;;
      kenobi)  ssh root@100.73.101.89 ;;
      *)       echo "Unknown host: {{ host }}"; exit 1 ;;
    esac

# Check closure sizes on all hosts.
[doc('Show NixOS closure sizes on all hosts')]
closure-sizes:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Closure Sizes ==="
    for pair in "chopper:100.107.213.17" "kenobi:100.73.101.89"; do
      name="${pair%%:*}"
      ip="${pair##*:}"
      size=$(ssh -o ConnectTimeout=5 root@$ip \
        "nix-store -qR /run/current-system | xargs nix-store --query --size | awk '{s+=\$1} END {printf \"%.2f GiB\", s/1073741824}'" 2>/dev/null || echo "unreachable")
      printf "  %-10s %s\n" "$name" "$size"
    done

# Run garbage collection on a host.
[doc('Garbage-collect old generations on a host')]
gc host:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ host }}" in
      chopper) ssh root@100.107.213.17 "nix-collect-garbage -d && nix-store --optimise" ;;
      kenobi)  ssh root@100.73.101.89 "nix-collect-garbage -d && nix-store --optimise" ;;
      *)       echo "Unknown host: {{ host }}"; exit 1 ;;
    esac

# Garbage-collect all hosts.
[doc('Garbage-collect all hosts')]
gc-all: (gc "chopper") (gc "kenobi")

# Collect local garbage.
[doc('Garbage-collect the local Mac nix store')]
clean:
    nix-collect-garbage -d

# ═══════════════════════════════════════════════════════════════════════════
#  FLAKE — input management
# ═══════════════════════════════════════════════════════════════════════════

# Update flake.lock from a local git checkout (skips GitHub archive download).
# Usage: just fast-update nixpkgs ../nixpkgs
[doc('Update a flake input from a local git repo (e.g. just fast-update nixpkgs ~/code/nixpkgs)')]
fast-update input repo:
    fast-flake-update {{ input }} {{ repo }}

# Update all flake inputs (standard nix flake update).
[doc('Update all flake inputs')]
flake-update:
    nix flake update
