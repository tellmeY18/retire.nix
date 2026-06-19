---
name: nix-rebuild
description: Use nh (not nixos-rebuild/darwin-rebuild/home-manager) for all Nix system switches, builds, and activations. Also governs terminal output rules — never truncate logs from builds or deploys.
---

# Nix Rebuild with nh

## Always use `nh` — never the raw nix commands

`nh` is the canonical wrapper for applying Nix configs in this setup. Never use:
- `nixos-rebuild switch` → use `nh os switch`
- `darwin-rebuild switch` → use `nh darwin switch`
- `home-manager switch` → use `nh home switch`

### Command reference

| Goal | Command |
|---|---|
| Apply NixOS config (any Linux host) | `nh os switch /etc/nixos` or `nh os switch <flake-dir>#<host>` |
| Apply darwin config (macOS) | `nh darwin switch <flake-dir>` |
| Apply Home Manager config | `nh home switch <flake-dir>` |
| Dry-run / diff without switching | append `--dry` to any of the above |
| Build without activating | append `--no-activate` |
| Pass extra nix flags | append `-- <nix flags>` after the nh args |

`nh` auto-detects the flake root if run from inside the repo. In this repo the flake is at `/Users/mathew/.config/nix` on darwin and `/etc/nixos` on NixOS hosts.

### Flake selectors

When a specific host or home config must be targeted, use the `--flake` flag:

```
nh os switch --flake /Users/mathew/.config/nix#chopper
nh darwin switch --flake /Users/mathew/.config/nix
nh home switch --flake /Users/mathew/.config/nix#"mathewalex@Vysakhs-MacBook-Pro"
```

## Terminal output rules — never go blind

**Never use `head_lines` or `tail_lines` on build, switch, deploy, or any long-running Nix operation.** These commands produce output the user MUST be able to see in full:

- `nh os switch ...`
- `nh darwin switch ...`
- `nh home switch ...`
- `nix build ...`
- `nix flake check ...`
- `deploy-rs` / `just deploy ...`
- `kubectl apply ...`, `helmfile sync ...`
- Any CI/CD log replay

For these commands, call `terminal` with **no** `head_lines` or `tail_lines` set. The full output streams to the user's terminal in real time and is returned in full to the agent.

Only use `head_lines`/`tail_lines` for purely diagnostic read-only commands (e.g. `git log`, `ps aux`, `df -h`) where truncation cannot hide a failure.

### Timeouts

Build and switch operations can take several minutes. Use generous `timeout_ms` values:
- Simple switch (cache hits likely): `300000` (5 min)
- Full rebuild (many derivations): `900000` (15 min)
- deploy-rs to a remote node: `600000` (10 min)

If a command times out, report it clearly and let the user decide whether to re-run with a longer timeout. Do not silently retry.
