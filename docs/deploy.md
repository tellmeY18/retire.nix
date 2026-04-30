# Remote Deployment with deploy-rs

This repository uses [deploy-rs](https://github.com/serokell/deploy-rs) to
push NixOS configuration updates to remote machines from your local workstation.

## Architecture

```
Mac (aarch64-darwin)                    chopper (x86_64-linux)
┌──────────────────┐    SSH/Tailscale   ┌──────────────────┐
│  deploy-rs CLI   │ ────────────────►  │  nix build       │
│  (orchestrator)  │                    │  (remote build)  │
│                  │ ◄────────────────  │  activate/switch │
└──────────────────┘    result path     └──────────────────┘
```

**Remote build mode** — the target machine builds its own closure. This avoids
cross-architecture compilation issues (aarch64-darwin → x86_64-linux). Your Mac
only orchestrates; chopper does the heavy lifting.

## Prerequisites

- SSH access to the target host (key-based, via Tailscale)
- The target host must be able to build its own configuration (has Nix installed)
- `deploy-rs` available in the dev shell (`nix develop`)

## Quick start

```sh
# Enter the dev shell
nix develop

# Deploy to a specific host
deploy .#chopper

# Deploy to all hosts
deploy .

# Dry run (build but don't activate)
deploy .#chopper -- --dry-activate

# Skip checks
deploy .#chopper --skip-checks
```

Or using the Justfile:

```sh
just deploy-chopper
just deploy-all
just deploy-dry chopper
```

## How it works

1. **Discovery** — `lib/default.nix` scans `hosts/*/metadata.nix` for hosts
   with a `deploy` attribute
2. **Node generation** — `mkDeployNodes` creates deploy-rs node configs from
   the metadata (hostname, SSH user, remote build flag)
3. **Deployment** — deploy-rs SSHs to the target, triggers a remote `nix build`,
   copies the result to the Nix store, and runs the activation script
4. **Activation** — equivalent to `nixos-rebuild switch`

## Adding deploy support to a host

Add a `deploy` attribute to the host's `metadata.nix`:

```nix
{
  hostname = "myhost";
  system = "x86_64-linux";
  type = "nixos";
  # ... other metadata ...

  deploy = {
    host = "100.x.y.z";        # Tailscale IP or resolvable hostname
    sshUser = "root";           # Must have permission to switch system profiles
    remoteBuild = true;         # Target builds its own closure
  };
}
```

That's it — `nix flake show` will include the new node under `deploy.nodes`.

## Configuration options

| Option | Default | Description |
|--------|---------|-------------|
| `deploy.host` | (required) | SSH-reachable hostname or IP |
| `deploy.sshUser` | `"root"` | SSH user for the deployment |
| `deploy.remoteBuild` | `true` | Build on target instead of locally |

## Troubleshooting

### "connection refused" or SSH timeout
- Verify Tailscale is up: `tailscale status`
- Check SSH access: `ssh root@100.107.213.17`

### "permission denied" on activation
- deploy-rs needs root to switch system profiles
- Ensure `sshUser = "root"` and root has your SSH key in `authorizedKeys`
- Check `users/vysakh.nix` — the SSH keys there are applied to both `vysakh` and `root`

### Remote build fails
- Ensure the target has enough disk space
- Check the target can reach nixpkgs caches: `curl -I https://cache.nixos.org`
- If remote build is problematic, set `remoteBuild = false` and use your Mac's
  distributed build setup (already configured to delegate to chopper)

### Rollback
deploy-rs creates a profile entry on each deploy. To rollback:
```sh
# On the target machine:
nixos-rebuild switch --rollback

# Or list generations and switch:
nix-env --list-generations --profile /nix/var/nix/profiles/system
nix-env --switch-generation <N> --profile /nix/var/nix/profiles/system
/nix/var/nix/profiles/system/bin/switch-to-configuration switch
```
