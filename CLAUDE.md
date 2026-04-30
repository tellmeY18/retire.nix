# CLAUDE.md — Repository Audit & Cleanup Guide

This document is an opinionated audit of the current Nix flake and a checklist
of improvements to make this repository a **truly reproducible, multi-system
Nix configuration**. It is intended as ongoing context for AI assistants
(Claude / Copilot / etc.) and human contributors.

> Companion document: see `ROADMAP.md` for the milestone plan that operationalises
> the items below.

---

## 1. Repository Snapshot (current state)

```
.
├── flake.nix
├── flake.lock
├── hosts/
│   ├── darwin/                 # Vysakhs-MacBook-Pro
│   │   ├── configuration.nix
│   │   ├── programs.nix
│   │   ├── services.nix
│   │   └── NVIM.md
│   └── chopper/                # NixOS + ZFS + Disko laptop
│       ├── configuration.nix
│       ├── default.nix         # bulk of the host config lives here
│       ├── disko-config.nix
│       └── hardware-configuration.nix
├── home/
│   ├── darwin-home.nix
│   ├── linux-home.nix
│   ├── common/                 # cross-platform HM modules
│   ├── darwin/                 # mac-only HM modules
│   └── chopper/                # chopper-only HM modules
├── modules/                    # NixOS service modules
│   ├── arr.nix conduit.nix care.nix garage.nix
│   ├── neondb.nix nextcloud.nix zfs.nix
├── packages/
│   ├── default.nix
│   ├── chopper/  darwin/  neondb/
└── README.md
```

Hosts defined:
- `darwinConfigurations."Vysakhs-MacBook-Pro"` (aarch64-darwin)
- `nixosConfigurations.chopper` (x86_64-linux, ZFS root via disko)
- `homeConfigurations."mathewalex@Vysakhs-MacBook-Pro"`
- `homeConfigurations."vysakh@chopper"`

---

## 2. High-Level Findings

### 2.1 Reproducibility issues (BLOCKERS)

These directly break the "truly reproducible" promise:

1. **Hard-coded absolute paths to user secrets.** `hosts/chopper/default.nix`
   references `/home/vysakh/tail.key`, `/home/vysakh/entepass`,
   `/home/vysakh/.cloudflared/<uuid>.json`. None of these are tracked or
   provisioned — the system is not buildable from scratch on a fresh machine.
2. **Plaintext-ish secrets paths.** Auth keys, admin passwords, and tunnel
   credentials are placed in `/etc` via `environment.etc` from a user home
   path. `sops-nix` is in the inputs but **not actually used anywhere**.
3. **`hostId` and tunnel UUIDs are committed.** Fine for `chopper`, but there
   is no abstraction for a second host — copy/paste would propagate them.
4. **Personal identity baked into modules.** Username (`vysakh`,
   `mathewalex`), git email (`vysakhpr218@gmail.com`), full name, SSH public
   keys, hostnames, and timezone are hard-coded throughout instead of being
   parameters.
5. **`nix.programs.nh.flake = "/etc/nixos"`** assumes this repo is checked
   out at `/etc/nixos` on chopper, which contradicts a flake-based workflow.
6. **Insecure permitted package pinned by version string** (`conduwuit-0.4.6`)
   without a comment justifying it or a tracking issue.
7. **`PermitRootLogin = "yes"`** on OpenSSH — reproducible, but a security
   foot-gun that should be intentional, documented, or removed.
8. **`wheelNeedsPassword = false`** — same: explicit + documented or revert.

### 2.2 Flake hygiene

1. `flake-utils.lib.eachSystem` is used only to expose `formatter` and a
   `packages.default` that re-exports a Fenix toolchain. The systems list
   (`aarch64-darwin`, `x86_64-linux`) is **not** the source of truth driving
   the host configurations — they hard-code their `system` strings. Drift is
   inevitable.
2. The Fenix overlay + Rust toolchain block is **duplicated** between the
   darwin and chopper module lists. Should live in a shared module.
3. `nix-homebrew` config is inlined in `flake.nix` instead of `hosts/darwin/`.
4. `cook` input is commented out; either remove or restore.
5. No `devShells.<system>.default` — `nix develop` referenced in README has
   nothing to enter.
6. No `checks.<system>` — `nix flake check` will not validate host builds in
   CI.
7. No pin/strategy for `nixpkgs` channel switch (everything tracks
   `nixpkgs-unstable`); no `nixos-<release>` fallback for stable services.
8. Outputs are not `lib.genAttrs`-style; adding a third host requires
   editing `flake.nix` directly.

### 2.3 Module / structure issues

1. `hosts/chopper/default.nix` is a **350+ line god-file** mixing power
   management (TLP), SSH, greetd, Tailscale, Nextcloud, Cloudflared,
   ZFS maintenance, Docker, networking, users, and shell config. It should
   be split into focused modules under `modules/` or `hosts/chopper/parts/`.
2. `modules/` mixes "service wrappers I wrote" (`neondb.nix`, `care.nix`,
   `garage.nix`, `conduit.nix`) with config (`zfs.nix`). They should be
   converted into proper NixOS modules with `options.services.<name>` and
   imported only by hosts that need them — not dropped into one host.
3. No `lib/` directory for shared helpers (`mkHost`, `mkHome`, user
   factory, etc.).
4. `home/` has both `common/` and per-host overlays, but several modules
   (e.g. `kitty`) are duplicated between `home/common/kitty` and
   `home/chopper/kitty` — pick one.
5. `packages/default.nix` exists but `flake.nix` calls
   `final.callPackage ./packages/neondb/default.nix` directly — overlays
   and packages are not unified.
6. Stale paths in `README.md`: it documents `overlays/`, `scripts/`,
   `packages/chopper/`, `modules/esp.nix` — none of which exist (or no
   longer match reality).

### 2.4 Stylistic / tooling

1. No formatter pre-commit / treefmt config — `nixpkgs-fmt` is declared but
   not enforced. Mixed brace styles throughout.
2. No statix / deadnix / nil / nixd in a dev shell.
3. Many large commented-out blocks (`mopidy`, `cook`, etc.) — convert to
   `lib.mkIf` toggles or delete.
4. `lib.mkForce` used in `boot.zfs.package` and `forceImportAll` without
   explanatory comment.
5. `system.stateVersion` values exist but aren't centralised.
6. `home.stateVersion = "24.05"` for both, but channel is unstable — pick a
   policy and document it.
7. Inconsistent attribute style: some files use compact `{ a = b; }`, others
   use deeply nested attrset blocks for single options.

### 2.5 Documentation

1. `README.md` describes a structure that no longer exists.
2. `home/README.md` references files that don't exist (`common.nix`,
   `darwin.nix`, `chopper.nix`).
3. No `CONTRIBUTING.md`, no `docs/` for "how to add a new host", "how to
   add secrets", "how to bootstrap from scratch".
4. No diagram of module composition.

### 2.6 Security / secrets

1. `sops-nix` is wired in but unused — no `sops.secrets.*`, no `.sops.yaml`,
   no age key strategy.
2. SSH keys are inlined in `users.users.<name>.openssh.authorizedKeys.keys`.
   This is fine, but should live in a `lib/users.nix` factory.
3. Cloudflare tunnel credentials, Nextcloud admin password, Tailscale
   pre-auth key all in plaintext at home paths.
4. No firewall review per service (e.g. tailscale port allowed but
   `4000`, `80`, `443` are also opened unconditionally).

### 2.7 Testability / CI

1. No `.github/workflows/` — no `nix flake check`, no build matrix.
2. No `cachix` / attic push for build artifacts.
3. No `nixos-rebuild build` smoke test for hosts on PRs.
4. No `nix-fast-build` or equivalent.

### 2.8 Multi-system readiness gaps

To honestly claim "multi-system reproducibility":

- [ ] Adding a new NixOS host should be a single file: `hosts/<name>/default.nix`
      auto-discovered by `flake.nix`.
- [ ] Adding a new user/HM target should not require editing `flake.nix`.
- [ ] Hostname, user, fullName, email, gitEmail, sshKeys, timezone should
      come from a per-host `metadata.nix`.
- [ ] Hardware/disko configs must live entirely under `hosts/<name>/` and
      never leak host names elsewhere.
- [ ] Optional roles (server, laptop, dev, gaming, media) should be
      composable as profiles under `profiles/` or `roles/`.

---

## 3. Concrete improvement checklist

Grouped by area; ROADMAP.md sequences these into milestones.

### Flake structure
- [ ] Introduce `lib/mkHost.nix` and `lib/mkHome.nix` factories.
- [ ] Auto-discover `hosts/*` and `home/*/*` via `builtins.readDir`.
- [ ] Move Fenix/Rust block into `modules/dev/rust.nix`, import in both hosts.
- [ ] Move `nix-homebrew` config into `hosts/darwin/`.
- [ ] Add `devShells.default` (formatters, `nh`, `nixos-rebuild`, `sops`,
      `age`, `statix`, `deadnix`, `nil`/`nixd`).
- [ ] Add `checks.<system>` evaluating each host + each home configuration.
- [ ] Add `formatter = treefmt-nix` (nix + shell + md).

### Hosts
- [ ] Split `hosts/chopper/default.nix` into:
      `users.nix`, `network.nix`, `power.nix`, `services/*.nix`,
      `programs.nix`, `virtualisation.nix`.
- [ ] Move Cloudflared, Nextcloud, Tailscale, Conduit, *arr, Care into
      `modules/services/*` with `options.<...>.enable`.
- [ ] Stub a second host (`hosts/template/`) to validate parameterisation.
- [ ] Remove `programs.nh.flake = "/etc/nixos"`; let `nh` discover the flake.

### Home Manager
- [ ] Deduplicate `kitty`, `zsh` between `home/common` and `home/<host>`.
- [ ] Use `osConfig` predicates (`pkgs.stdenv.isDarwin`) instead of
      maintaining parallel trees where possible.
- [ ] Promote shared `git`, `tmux`, `direnv` to fully parameterised modules
      (name/email from `metadata`).

### Secrets (sops-nix)
- [ ] Add `.sops.yaml` with age recipients per host + admin user.
- [ ] Migrate Tailscale auth key, Nextcloud admin password, Cloudflare
      tunnel JSON to `sops.secrets.*`.
- [ ] Document key rotation and bootstrap procedure.

### Packages / overlays
- [ ] Create `overlays/default.nix` and consume it from both hosts.
- [ ] Move `neondb` overlay into `overlays/`.
- [ ] Audit `packages/chopper`, `packages/darwin` — convert to overlays or
      proper packages exposed via `packages.<system>.<name>`.

### Documentation
- [ ] Rewrite `README.md` to match reality.
- [ ] Rewrite `home/README.md`.
- [ ] Add `docs/bootstrap-darwin.md`, `docs/bootstrap-nixos.md`,
      `docs/add-a-host.md`, `docs/secrets.md`.
- [ ] Add a Mermaid diagram of module composition.

### Tooling / CI
- [ ] Add `treefmt.nix` + `pre-commit-hooks.nix` (or `git-hooks.nix`).
- [ ] Add GitHub Actions: `nix flake check`, build all hosts on push.
- [ ] Optional: Cachix / Attic binary cache push.
- [ ] Add `statix check` and `deadnix` to CI.

### Security
- [ ] Audit SSH config (`PermitRootLogin`, key-only, port).
- [ ] Audit firewall — close `4000` unless needed; bind services to
      `localhost` and front via Cloudflared.
- [ ] Justify or revert `wheelNeedsPassword = false`.
- [ ] Justify or remove `permittedInsecurePackages`.

### Hygiene
- [ ] `nix run nixpkgs#deadnix` — remove dead bindings.
- [ ] `nix run nixpkgs#statix` — fix lints.
- [ ] Delete commented-out service blocks (mopidy, cook, etc.).
- [ ] Centralise `stateVersion` policy with comments.

---

## 4. Conventions (proposed)

These should be enforced going forward:

- **One module = one concern.** No "kitchen sink" host files.
- **No hard-coded user paths.** Use `config.users.users.<name>.home`,
  `config.home.homeDirectory`, or sops paths.
- **Per-host metadata** in `hosts/<name>/metadata.nix`:
  ```nix
  {
    hostname = "chopper";
    system   = "x86_64-linux";
    hostId   = "91d4eb37";
    timezone = "Asia/Kolkata";
    users    = [ "vysakh" ];
    roles    = [ "laptop" "server" "zfs" ];
  }
  ```
- **Per-user metadata** in `users/<name>.nix`: name, email, ssh keys,
  default shell.
- **Profiles/roles** in `profiles/<role>.nix`: composed by hosts.
- **Formatting**: `treefmt` is canonical; no manual style debates.
- **Stable channels for stable services** (e.g. Nextcloud, Postgres):
  pin via a second `nixpkgs-stable` input if needed.

---

## 5. Files / paths flagged for action (quick index)

| File | Action |
|---|---|
| `flake.nix` | Refactor outputs into `lib/mk*.nix`, dedupe Fenix block, add `devShells`/`checks`. |
| `hosts/chopper/configuration.nix` | Trim to `imports = []` + `metadata`. |
| `hosts/chopper/default.nix` | Split into multiple files / modules. |
| `hosts/darwin/configuration.nix` | Move builder + cache config to `modules/`. |
| `home/README.md` | Rewrite; remove dead references. |
| `README.md` | Rewrite; remove `overlays/`, `scripts/`, `esp.nix` references. |
| `modules/*` | Convert to proper NixOS modules with options. |
| `packages/default.nix` | Either populate or delete; unify with overlays. |

---

## 6. Definition of Done

The repository is "truly reproducible multi-system" when:

1. A fresh machine + this repo + an age key can rebuild any host with
   `nh os switch` / `nh darwin switch` (no manual file copying).
2. `nix flake check` is green in CI for all hosts and all HM configs.
3. Adding a new host = `mkdir hosts/<name> && $EDITOR metadata.nix`.
4. No personal identifiers leak outside `users/*` and `hosts/*/metadata.nix`.
5. `sops` owns every secret currently sitting at a `/home/<user>/...` path.
6. `README.md` is accurate.
