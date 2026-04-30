# Baseline Snapshot — 2025-07-15 (Pre-Cleanup)

This document captures the exact state of the Nix flake inputs and build
targets **before** any cleanup work begins (Milestone 0 of [ROADMAP.md](../../ROADMAP.md)).

The commit that introduces this file should be tagged as **`pre-cleanup-baseline`**.

---

## Hosts

| Host | System | Configuration Attribute |
|---|---|---|
| `Vysakhs-MacBook-Pro` | `aarch64-darwin` | `darwinConfigurations."Vysakhs-MacBook-Pro"` |
| `chopper` | `x86_64-linux` | `nixosConfigurations.chopper` |

Home Manager targets:

| User @ Host | Configuration Attribute |
|---|---|
| `mathewalex@Vysakhs-MacBook-Pro` | `homeConfigurations."mathewalex@Vysakhs-MacBook-Pro"` |
| `vysakh@chopper` | `homeConfigurations."vysakh@chopper"` |

---

## Build Targets to Verify

Before and after every milestone, these four artifacts must build successfully:

```text
# macOS system (run on aarch64-darwin)
nix build .#darwinConfigurations.Vysakhs-MacBook-Pro.system

# NixOS system (run on x86_64-linux, or cross-evaluate)
nix build .#nixosConfigurations.chopper.config.system.build.toplevel

# Home Manager — macOS
nix build .#homeConfigurations."mathewalex@Vysakhs-MacBook-Pro".activationPackage

# Home Manager — NixOS
nix build .#homeConfigurations."vysakh@chopper".activationPackage
```

---

## Flake Input Revisions

Extracted from `flake.lock` (lock file version 7).

### Direct Inputs

| Input | Owner / Repo | Branch / Ref | Revision | Last Modified |
|---|---|---|---|---|
| **nixpkgs** | `NixOS/nixpkgs` | `nixpkgs-unstable` | `8d8c1fa5b412c223ffa47410867813290cdedfef` | 2025-05-30 |
| **home-manager** | `nix-community/home-manager` | — | `2097a5c82bdc099c6135eae4b111b78124604554` | 2025-06-02 |
| **nix-darwin** | `LnL7/nix-darwin` | — | `06648f4902343228ce2de79f291dd5a58ee12146` | 2025-05-29 |
| **fenix** | `nix-community/fenix` | — | `3dc46f7171ba708c559458d6f76043948a97efdf` | 2025-06-17 |
| **disko** | `nix-community/disko` | — | `5ad85c82cc52264f4beddc934ba57f3789f28347` | 2025-06-16 |
| **sops-nix** | `Mic92/sops-nix` | — | `a4ee2de76efb759fe8d4868c33dec9937897916f` | 2025-06-02 |
| **flake-utils** | `numtide/flake-utils` | — | `11707dc2f618dd54ca8739b309ec4fc024de578b` | 2024-11-13 |
| **nix-homebrew** | `zhaofengli/nix-homebrew` | — | `a7760a3a83f7609f742861afb5732210fdc437ed` | 2025-05-25 |
| **nixvim** | `nix-community/nixvim` | — | `2e008bb941f72379d5b935d5bfe70ed8b7c793ff` | 2025-06-02 |
| **nix-index-database** | `nix-community/nix-index-database` | — | `cef5cf82671e749ac87d69aadecbb75967e6f6c3` | 2025-06-02 |

### Transitive / Indirect Inputs

| Input | Owner / Repo | Ref | Revision | Notes |
|---|---|---|---|---|
| **brew-src** | `Homebrew/brew` | `5.1.1` | `894a3d23ac0c8aaf561b9874b528b9cb2e839201` | via `nix-homebrew` |
| **flake-parts** | `hercules-ci/flake-parts` | — | `57928607ea566b5db3ad13af0e57e921e6b12381` | via `nixvim` |
| **rust-analyzer-src** | `rust-lang/rust-analyzer` | `nightly` | `251df518d73abb5c5d573c4d5d266a3edae9ca5a` | via `fenix` |
| **systems** | `nix-systems/default` | — | `da67096a3b9bf56a91d16901293e51ba5b49a27e` | via `flake-utils` |

### Input Follows

Most inputs follow `nixpkgs` from the root to avoid duplicate evaluations:

- `disko.nixpkgs` → root `nixpkgs`
- `fenix.nixpkgs` → root `nixpkgs`
- `home-manager.nixpkgs` → root `nixpkgs`
- `nix-darwin.nixpkgs` → root `nixpkgs`
- `sops-nix.nixpkgs` → root `nixpkgs`
- `nixvim.nixpkgs` → root `nixpkgs`
- `nix-index-database.nixpkgs` → root `nixpkgs`

---

## Key Observations at Baseline

- All inputs track latest / unstable. No stable channel pin exists.
- `sops-nix` is present as an input but **not wired into any host configuration** — secrets are currently managed via plaintext paths.
- `flake-utils` is used only for `eachSystem` (formatter + packages); hosts hard-code their `system` strings independently.
- The `cook` input referenced in `CLAUDE.md` is no longer present in the lock file (already removed or commented out in `flake.nix`).
- Lock file version is **7** (Nix ≥ 2.18 format).

---

## Tagging

After committing this file, tag the commit:

```text
git tag -a pre-cleanup-baseline -m "Baseline snapshot before cleanup (Milestone 0)"
git push origin pre-cleanup-baseline
```

This tag serves as the rollback point if any milestone introduces a regression.
