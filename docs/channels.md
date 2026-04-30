# Channel & State Version Policy

## Nixpkgs channels

This flake uses two nixpkgs inputs:

| Input | Channel | Purpose |
|-------|---------|---------|
| `nixpkgs` | `nixpkgs-unstable` | Default for all hosts — latest packages, drivers, kernels |
| `nixpkgs-stable` | `nixos-25.11` | Pinned for production services that need predictable upgrades |

### When to use stable

Use `nixpkgs-stable` for:
- **Nextcloud** — major version upgrades require manual intervention
- **PostgreSQL** — major version bumps need `pg_upgrade`
- **ZFS** — kernel/module compatibility is critical

To use a stable package in a host config:
```nix
# In the host's extraModules (flake.nix):
({ pkgs, ... }: let
  pkgs-stable = import inputs.nixpkgs-stable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in {
  services.nextcloud.package = pkgs-stable.nextcloud32;
})
```

### When to use unstable

Everything else — desktop packages, dev tools, CLI utilities, etc. Unstable
tracks the latest commits to `nixpkgs` and gets new package versions fastest.

## State version policy

`system.stateVersion` and `home.stateVersion` are **not** the same as the
nixpkgs channel. They control NixOS/Home Manager's internal state migration
behavior.

### Rules

1. **Never change stateVersion on an existing host** unless you understand
   the migration implications (see [NixOS docs](https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion)).
2. **New hosts** should use the latest stable release version (currently `"25.11"`).
3. **Home Manager stateVersion** follows the same convention.

### Current values

| Target | stateVersion |
|--------|-------------|
| `nixosConfigurations.chopper` | `"24.11"` |
| `darwinConfigurations.Vysakhs-MacBook-Pro` | `5` (darwin scheme) |
| `homeConfigurations."vysakh@chopper"` | `"24.05"` |
| `homeConfigurations."mathewalex@Vysakhs-MacBook-Pro"` | `"24.05"` |

### Upgrade procedure

When a new NixOS release (e.g., 25.05) is available:

1. Update `nixpkgs-stable` URL to the new release (e.g. `github:NixOS/nixpkgs/nixos-26.05`)
2. Run `nix flake update nixpkgs-stable`
3. Test: `just build-all`
4. Do NOT bump `system.stateVersion` unless explicitly needed
5. Update this document's "Current values" table
