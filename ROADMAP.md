# ROADMAP.md — Path to a Truly Reproducible Multi-System Nix Config

This roadmap operationalises the audit in [`CLAUDE.md`](./CLAUDE.md) into
sequenced milestones. Each milestone is a coherent unit of work that leaves
the repository in a buildable state and unlocks the next one.

**Legend**
- `[ ]` not started · `[~]` in progress · `[x]` done
- 🔒 = security-relevant · 🧪 = adds tests / CI · 📚 = docs · 🧹 = pure cleanup
- Effort: S (≤1h) · M (a few hours) · L (a day or more)

> Rule: do **not** start a milestone until the previous one is green
> (`nix flake check` passes and both hosts still build).

---

## Milestone 0 — Baseline & Safety Net  ·  🧪 📚  ·  Effort: S

Goal: know exactly what we have and never regress silently.

- [ ] Tag the current commit as `pre-cleanup-baseline`.
- [ ] Capture current build outputs:
  - [ ] `nix build .#darwinConfigurations.Vysakhs-MacBook-Pro.system` (on mac)
  - [ ] `nix build .#nixosConfigurations.chopper.config.system.build.toplevel`
  - [ ] `nix build .#homeConfigurations."mathewalex@Vysakhs-MacBook-Pro".activationPackage`
  - [ ] `nix build .#homeConfigurations."vysakh@chopper".activationPackage`
- [ ] Add a `flake check` smoke target (even if it only evaluates inputs).
- [ ] Snapshot `flake.lock` and note current input revisions in
      `docs/baselines/<date>.md`.
- [ ] Add this `ROADMAP.md` and `CLAUDE.md` to the repo root. ✅

**Exit criteria:** all four artifacts build; baseline tag exists.

---

## Milestone 1 — Documentation Reality Check  ·  📚 🧹  ·  Effort: S

Goal: stop lying to readers (and to ourselves).

- [ ] Rewrite `README.md`:
  - [ ] Remove references to `overlays/`, `scripts/`, `packages/chopper/`,
        `modules/esp.nix`.
  - [ ] Document the actual structure (mirror `CLAUDE.md` §1).
  - [ ] Document supported hosts and how to build each.
- [ ] Rewrite `home/README.md`:
  - [ ] Replace `common.nix` / `darwin.nix` / `chopper.nix` references with
        the real `home/{darwin-home,linux-home}.nix` entry points and
        `home/{common,darwin,chopper}/` trees.
- [ ] Add `CONTRIBUTING.md` skeleton (formatting, commit style, "how to add
      a host" pointer).

**Exit criteria:** every path mentioned in markdown exists in the repo.

---

## Milestone 2 — Dev Shell, Formatter, Lints  ·  🧪 🧹  ·  Effort: M

Goal: any contributor can run a single command and have the right tools.

- [ ] Add `devShells.<system>.default` providing:
      `nixpkgs-fmt`, `treefmt`, `statix`, `deadnix`, `nil`, `nixd`,
      `sops`, `age`, `ssh-to-age`, `nh`, `git`, `just` (optional).
- [ ] Add `treefmt.nix` (or `treefmt-nix` flake-module) covering:
      `*.nix` → `nixpkgs-fmt`, `*.md` → `mdformat`, `*.sh` → `shfmt`.
- [ ] Set `formatter.<system> = treefmt`.
- [ ] Run `nix fmt` once across the whole tree; commit the noise separately.
- [ ] Run `statix check` and `deadnix` once; fix or `# noqa`-justify
      remaining hits.
- [ ] Add a `Justfile` (or `flake.nix` apps) for common chores:
      `just fmt`, `just check`, `just build-chopper`, `just build-mac`.

**Exit criteria:** `nix develop` enters a shell with all tools;
`nix fmt && nix flake check` is green.

---

## Milestone 3 — `lib/` factories & flake refactor  ·  🧹  ·  Effort: M

Goal: `flake.nix` becomes a thin orchestrator, not a config dump.

- [ ] Create `lib/default.nix` exposing:
  - [ ] `mkHost { hostname, system, modules ? [], extraModules ? [] }`
  - [ ] `mkDarwinHost { ... }`
  - [ ] `mkHome { username, hostname, system, modules ? [] }`
  - [ ] `forAllSystems` helper (replace ad-hoc `flake-utils.lib.eachSystem`).
- [ ] Move the duplicated Fenix/Rust block into `modules/dev/rust.nix`;
      import it from both hosts.
- [ ] Move the `nix-homebrew` config block from `flake.nix` into
      `hosts/darwin/homebrew.nix` (imported by `hosts/darwin/configuration.nix`).
- [ ] Replace explicit `darwinConfigurations` and `nixosConfigurations`
      bodies with calls to the new factories.
- [ ] Make the systems list (`["aarch64-darwin" "x86_64-linux"]`) the single
      source of truth — derive it from the discovered hosts where possible.
- [ ] Decide on `cook` input: restore with a `lib.mkIf` toggle **or** delete.

**Exit criteria:** `flake.nix` is < 100 lines; both hosts still build;
`nix flake check` green.

---

## Milestone 4 — Per-Host Metadata & Auto-Discovery  ·  🧹  ·  Effort: M

Goal: adding a host = create a directory.

- [ ] Define schema for `hosts/<name>/metadata.nix`:
      `{ hostname, system, hostId?, timezone, users, roles, stateVersion }`.
- [ ] Migrate `chopper` and `Vysakhs-MacBook-Pro` to the schema.
- [ ] Implement `lib.discoverHosts ./hosts` that scans for
      `metadata.nix` files and returns the appropriate
      `nixosConfigurations` / `darwinConfigurations`.
- [ ] Same idea for `homeConfigurations` keyed `${user}@${hostname}`.
- [ ] Add `hosts/template/` (NixOS) and `hosts/template-darwin/` examples
      that build but do nothing harmful (no real users / secrets).
- [ ] Update `docs/add-a-host.md`.

**Exit criteria:** removing a host directory is the only thing needed to
remove a host; adding one needs no `flake.nix` edits.

---

## Milestone 5 — Decompose `hosts/chopper/default.nix`  ·  🧹  ·  Effort: L

Goal: kill the 350-line god-module.

- [ ] Create `hosts/chopper/parts/`:
  - [ ] `boot.nix` — bootloader + ZFS overrides.
  - [ ] `network.nix` — networking, firewall, DNS.
  - [ ] `power.nix` — TLP + logind.
  - [ ] `display.nix` — greetd, sway, polkit, pam.
  - [ ] `virtualisation.nix` — docker, podman.
  - [ ] `programs.nix` — zsh/git/tmux/nh/lazygit (system-level only;
        prefer Home Manager).
- [ ] Move all `services.*` blocks into proper modules under
      `modules/services/*` with `options.<svc>.enable`:
  - [ ] `tailscale.nix`
  - [ ] `nextcloud.nix` (already exists — convert to optionised module)
  - [ ] `cloudflared.nix`
  - [ ] `openssh.nix`
  - [ ] `zfs-maintenance.nix`
- [ ] `hosts/chopper/configuration.nix` becomes ~20 lines: imports +
      `metadata`.

**Exit criteria:** no host file exceeds ~120 lines; module list in
`hosts/chopper/configuration.nix` reads like a table of contents.

---

## Milestone 6 — Users as First-Class Citizens  ·  🧹 🔒  ·  Effort: M

Goal: no personal identity leaks outside `users/*`.

- [ ] Create `users/<name>.nix` for each user:
      `{ username, fullName, email, sshKeys, shell, extraGroups }`.
- [ ] Create `lib.mkUser` that consumes that schema and produces both
      `users.users.<name>` (NixOS/Darwin) and HM `home.*` defaults.
- [ ] Migrate `vysakh`, `mathewalex`, `root` (keys only) to this scheme.
- [ ] Make git `user.name` / `user.email` come from the user record
      (in HM `programs.git`).

**Exit criteria:** grepping for `vysakhpr218@gmail.com` returns hits only
in `users/vysakh.nix`.

---

## Milestone 7 — Secrets via sops-nix  ·  🔒 📚  ·  Effort: L

Goal: kill every `/home/vysakh/<secret>` reference.

- [ ] Generate per-host age keys (`ssh-to-age` from existing host SSH
      keys); document in `docs/secrets.md`.
- [ ] Add `.sops.yaml` with creation rules per host.
- [ ] Create `secrets/` with encrypted files:
  - [ ] `secrets/chopper/tailscale-authkey`
  - [ ] `secrets/chopper/nextcloud-admin-pass`
  - [ ] `secrets/chopper/cloudflared/<uuid>.json`
- [ ] Wire `sops.secrets.*` into:
  - [ ] `services.tailscale.authKeyFile`
  - [ ] `services.nextcloud.config.adminpassFile`
  - [ ] `services.cloudflared.tunnels.*.credentialsFile`
- [ ] Remove the `environment.etc."tailscale/auth.key".source =
      "/home/vysakh/tail.key"` hack.
- [ ] Document bootstrap: "how to provision a new host given the age key".

**Exit criteria:** `git grep '/home/vysakh/'` returns 0 hits; a fresh
machine can be brought up given only this repo + an age key.

---

## Milestone 8 — Home Manager Cleanup  ·  🧹  ·  Effort: M

Goal: stop maintaining parallel trees.

- [ ] Audit duplicates between `home/common/` and `home/{darwin,chopper}/`:
  - [ ] `kitty` — collapse to one module gated by `pkgs.stdenv.isDarwin`.
  - [ ] `zsh` — same treatment.
- [ ] Convert `home/common/git` to read identity from the active user
      record (Milestone 6).
- [ ] Re-examine `home/common/packages` — split into role-based bundles
      (`cli`, `dev-rust`, `dev-web`, `media`, etc.) so hosts opt-in.
- [ ] Document the HM module hierarchy in `home/README.md`.

**Exit criteria:** no two files configure the same program with different
settings.

---

## Milestone 9 — Profiles / Roles  ·  🧹  ·  Effort: M

Goal: composable host archetypes.

- [ ] Create `profiles/`:
  - [ ] `profiles/base.nix` — locale, nix settings, common pkgs.
  - [ ] `profiles/laptop.nix` — TLP, lid handling, wifi.
  - [ ] `profiles/server.nix` — headless, no GUI, journald tuning.
  - [ ] `profiles/zfs.nix` — replaces `modules/zfs.nix`.
  - [ ] `profiles/wayland.nix` — sway/greetd/portals.
  - [ ] `profiles/dev.nix` — rust, docker, lazygit.
- [ ] Each host's `metadata.roles` selects which profiles get imported.
- [ ] Migrate `chopper` to declare `roles = [ "laptop" "server" "zfs"
      "wayland" "dev" ]`.

**Exit criteria:** the `template/` host can be turned into a "server"
host by toggling roles only.

---

## Milestone 10 — Packages & Overlays Unification  ·  🧹  ·  Effort: S

- [ ] Create `overlays/default.nix` aggregating all overlays.
- [ ] Move `neondb` callPackage out of `flake.nix` into
      `overlays/neondb.nix`.
- [ ] Audit `packages/chopper/` and `packages/darwin/` — convert to
      `packages.<system>.<name>` outputs.
- [ ] Either populate `packages/default.nix` meaningfully or delete it.

**Exit criteria:** `nix build .#<pkg>` works for every custom package;
`flake.nix` no longer contains overlay logic inline.

---

## Milestone 11 — CI & Caching  ·  🧪  ·  Effort: M

- [ ] Add `.github/workflows/check.yml`:
  - [ ] `nix flake check` on `ubuntu-latest` and `macos-latest`.
  - [ ] `statix check` and `deadnix --fail`.
  - [ ] `treefmt --fail-on-change`.
- [ ] Add `.github/workflows/build.yml`:
  - [ ] Build `nixosConfigurations.chopper` toplevel.
  - [ ] Build `darwinConfigurations.Vysakhs-MacBook-Pro` system.
  - [ ] Build both home configurations.
- [ ] (Optional) Push to Cachix or self-hosted Attic.
- [ ] Add status badges to `README.md`.

**Exit criteria:** PRs are blocked on red CI.

---

## Milestone 12 — Security Hardening Pass  ·  🔒  ·  Effort: M

- [ ] SSH:
  - [ ] Set `PermitRootLogin = "prohibit-password"` (or `no`); document.
  - [ ] Confirm `PasswordAuthentication = false` everywhere.
- [ ] Sudo: re-enable `wheelNeedsPassword = true` unless there is a
      written justification in `docs/security.md`.
- [ ] Firewall: bind Nextcloud / Conduit / Care to `127.0.0.1` and front
      via Cloudflared; close TCP `4000`, `80`, `443` on the public iface.
- [ ] Replace `permittedInsecurePackages = [ "conduwuit-0.4.6" ]` with a
      tracked upgrade or remove the service.
- [ ] Document the threat model briefly in `docs/security.md`.

**Exit criteria:** `nmap` against the host shows only the intended ports;
`docs/security.md` exists.

---

## Milestone 13 — Stable Channel & State Version Policy  ·  🧹 📚  ·  Effort: S

- [ ] Add a `nixpkgs-stable` input (matching the current NixOS release).
- [ ] Decide which services pin to stable (Nextcloud, Postgres, ZFS userland
      candidates) and wire them via `pkgs-stable` from a small overlay.
- [ ] Centralise `system.stateVersion` and `home.stateVersion` in
      `lib/stateVersion.nix` with a documented upgrade policy.

**Exit criteria:** `docs/channels.md` explains why a given service tracks
stable vs unstable.

---

## Milestone 14 — Second Real Host (Validation)  ·  🧪  ·  Effort: M

Goal: prove the abstractions work.

- [ ] Add a real (or VM) second NixOS host using only:
      `mkdir hosts/<name> && $EDITOR metadata.nix` plus a hardware import.
- [ ] Build it in CI.
- [ ] Document the journey in `docs/add-a-host.md` with screenshots/diff.

**Exit criteria:** the new host builds without touching any file outside
`hosts/<name>/` and `secrets/<name>/`.

---

## Milestone 15 — Final Polish  ·  📚 🧹  ·  Effort: S

- [ ] Add Mermaid diagram of module composition to `README.md`.
- [ ] Add `docs/bootstrap-darwin.md`, `docs/bootstrap-nixos.md`.
- [ ] Re-read every `TODO`/`FIXME`/commented block; resolve or file an issue.
- [ ] Tag `v1.0-reproducible` once the Definition of Done in `CLAUDE.md` §6
      is met.

---

## Cross-cutting backlog (pick up between milestones)

- [ ] 🧹 Replace nested single-key attrsets with compact form where it
      improves readability.
- [ ] 🧹 Standardise on `lib.mkEnableOption` / `lib.mkOption` patterns
      across all custom modules.
- [ ] 🧪 Add `nix-fast-build` or evaluation cache to speed up CI.
- [ ] 📚 Capture decisions in `docs/adr/000X-<title>.md` (ADR style).

---

## Suggested execution order (TL;DR)

1. **M0–M2**: safety net + dev experience (cheap wins, unblock everything).
2. **M3–M4**: refactor flake + introduce metadata (foundational).
3. **M5–M6**: split chopper, formalise users (biggest readability gain).
4. **M7**: secrets — the single most important reproducibility fix.
5. **M8–M10**: HM, profiles, overlays cleanups.
6. **M11–M12**: CI + security pass once the structure is stable.
7. **M13–M15**: polish, validation, release.
