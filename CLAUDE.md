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

---

## 7. Production-Grade k3s + CloudNativePG Architecture

This section captures the design for running a **production-grade k3s cluster
hosting CloudNativePG (CNPG)**, primarily on `chopper` (an old laptop), with a
path to **high availability** as more nodes are added. The PostgreSQL endpoint
must be reachable over Tailscale by webservices running in the cloud, and that
endpoint must survive any single host going down.

### 7.1 Goals & constraints

- **Primary host:** `chopper` — old laptop, ZFS root, already on the tailnet.
- **Workload:** PostgreSQL via CNPG (operator-managed, replicated, with PITR).
- **Consumers:** webservices in the cloud, joined to the same tailnet. They
  need a **stable Postgres URL** (host:port + creds) that is resilient to:
  - any one k3s node going down
  - the CNPG primary pod failing over
  - a node reboot (laptop power events are expected)
- **Future:** add a second laptop for redundancy; later a tiny always-on
  tailnet node as etcd quorum tiebreaker for true HA.
- **Reproducibility:** every component (k3s, operators, CNPG `Cluster`,
  backup config) must be declared in this repo. Manifests live in
  `k8s/` (Helm values + raw YAML or Kustomize), applied via GitOps.

### 7.2 Topology decisions

| Decision | Choice | Rationale |
|---|---|---|
| k3s datastore | **Embedded etcd** (`--cluster-init` on first server) | SQLite cannot be promoted to HA later. Etcd from day one means scale-out without rebuild. |
| Cluster traffic | Bound to `tailscale0` (`--node-ip`, `--bind-address`, `--advertise-address`, `--flannel-iface=tailscale0`) | All inter-node traffic (apiserver, etcd peers, flannel overlay, kubelet) rides the tailnet — no public exposure, encrypted by WireGuard. |
| Firewall | Open k3s ports **only** on `tailscale0` interface; public iface stays closed | Defence in depth; matches M12 hardening. |
| CNI | k3s default flannel (vxlan over tailnet) | Simple; sufficient for 2–3 nodes. Cilium is overkill here. |
| Ingress controller | Disabled (`--disable=traefik`) | We do not expose HTTP from the cluster — only Postgres over tailnet. Skip the attack surface. |
| Service load-balancer | Disabled (`--disable=servicelb`) | Replaced by the Tailscale operator for the one Service we expose. |
| Storage | **OpenEBS ZFS LocalPV** on chopper's existing zpool | Node-local, fast, snapshottable. CNPG handles replication at the PG layer (streaming + sync), so distributed block storage (Longhorn) would only add write amplification. |
| Postgres replication | CNPG `Cluster` with `instances: 3`, **synchronous** quorum-based replication, pod anti-affinity `requiredDuringSchedulingIgnoredDuringExecution` on `kubernetes.io/hostname` | Phase 1 (1 node): all 3 pods on chopper — no HA, but topology is already correct. Phase 2 (2 nodes): pods spread; primary failover survives one node loss. Phase 3 (3 nodes): full quorum. |
| Backups | CNPG → **Barman Cloud** → S3-compatible target (Garage on chopper for warm backups + an off-site bucket: Backblaze B2 / Cloudflare R2) | Off-site is the only thing that survives both laptops dying. PITR window ≥ 7 days. |
| Stable Postgres endpoint | **Tailscale Kubernetes Operator** exposing `<cluster>-rw` Service as `tailscale` LoadBalancer with a fixed MagicDNS hostname (e.g. `pg-rw`) | Webservices connect to `pg-rw.<tailnet>.ts.net:5432`. The ts-proxy pod is rescheduled by k8s when its node dies; tailnet routing follows. |
| kube-apiserver endpoint | `--tls-san` includes both nodes' tailscale FQDNs + a stable name; admin kubeconfig lists both servers | Avoids a hard dependency on a single node for `kubectl`. |
| GitOps | **None.** Nix bootstraps the install-once operators via `services.k3s.charts`; everything iterative is plain manifests + Helm charts applied via `helmfile` from this repo. | One operator (you). One cluster. Argo/Flux would add a second control loop, more RAM on an old laptop, and a second key-management surface for no net win. Re-evaluate if a second cluster appears. |
| Cluster config delivery | **Split:** (a) `services.k3s.charts` in NixOS for bootstrap-critical operators that must be present the moment k3s comes up (OpenEBS ZFS LocalPV, Tailscale operator, optionally cert-manager). (b) `helmfile` + raw YAML / kustomize under `k8s/` for everything iterative (CNPG operator, `Cluster`, `Pooler`, `ScheduledBackup`, `ObjectStore`, `Service`s). | Bootstrap operators come back automatically after a reboot with no human in the loop. Iterative resources don't require a `nixos-rebuild` cycle to tweak. |
| Observability | `kube-prometheus-stack` (lightweight values) + CNPG's built-in `PodMonitor`s | Optional but strongly recommended; alerting on replication lag is critical. |
| k3s upgrades | **System Upgrade Controller** with channel pin | Rolling upgrade with PDB respect. |

### 7.3 HA reality check (be honest about quorum)

- **1 node (today):** no HA. Single point of failure = chopper itself.
  CNPG can still failover the primary pod between local instances if a
  pod (not the node) crashes. Off-site backups are the only DR.
- **2 nodes:** still no true HA — etcd needs an **odd** quorum. Losing
  either node makes the cluster read-only and CNPG cannot promote a new
  primary safely. Useful only as a stepping stone.
- **3 nodes (target):** the third can be a tiny always-on tailnet member
  (cheap VPS, Pi, or a home-server VM). Tainted
  `node-role.kubernetes.io/control-plane:NoSchedule` and
  `quorum-only=true:NoExecute` so workloads (especially CNPG) never
  schedule there. Etcd quorum survives any single node loss.

This must be documented prominently in `docs/k3s-cnpg.md` so the user is
not surprised by the 2-node failure mode.

### 7.4 NixOS integration points

- New module: `modules/services/k3s.nix` with options:
  - `services.k3s-cluster.enable`
  - `services.k3s-cluster.role` = `"server-init" | "server" | "agent" | "quorum"`
  - `services.k3s-cluster.tailscaleInterface` (default `tailscale0`)
  - `services.k3s-cluster.clusterInit` (bool)
  - `services.k3s-cluster.serverAddr` (string, e.g. `https://chopper:6443`)
  - `services.k3s-cluster.tokenFile` (sops path)
  - `services.k3s-cluster.extraFlags` (list)
- Bootstrap operators declared via `services.k3s.charts.*` in NixOS
  (k3s renders these into `/var/lib/rancher/k3s/server/manifests/` and
  applies them on every boot):
  - `openebs-zfs-localpv` (provides the cluster's only `StorageClass`)
  - `tailscale-operator` (so `pg-rw` resolves the moment k3s is up)
  - optionally `cert-manager` (only if a future service needs it)
- Sops secrets (NixOS-side, consumed by systemd units):
  - `secrets/chopper/k3s-token` — shared cluster join token, fed via
    `services.k3s-cluster.tokenFile`
  - `secrets/chopper/tailscale-operator-oauth` — OAuth client for the
    Tailscale operator; rendered into a `Secret` by
    `services.k3s.manifests` from a sops-decrypted runtime path (NOT
    from the Nix store, which is world-readable).
- ZFS dataset for k3s/CNPG:
  - `rpool/k3s` mounted at `/var/lib/rancher/k3s` (recordsize=16K, atime=off)
  - `rpool/openebs` for ZFS LocalPV pool (recordsize=8K matches PG page,
    `logbias=throughput`, `compression=zstd`, `xattr=sa`)
  - Snapshots taken by `services.zfs.autoSnapshot` already configured.
- Firewall: add k3s ports to `interfaces.tailscale0.allowedTCPPorts` /
  `allowedUDPPorts` only — never to the global `firewall.allowed*Ports`.
- New role/profile: `profiles/k3s-node.nix` so any host can opt in by
  adding `"k3s"` to `metadata.roles`. The profile pulls in `kubectl`,
  `helm`, `helmfile`, the `helm-secrets` plugin, `k9s`, `cmctl`, and
  `sops` so the laptop is a self-sufficient admin client.

### 7.4a Secrets topology (the one place "YAML in git" breaks down)

We deliberately do **not** run Sealed Secrets or External Secrets
Operator. The existing `sops-nix` + age key-per-host setup is reused
as the single root of trust for cluster secrets too. `helmfile` gets
the `helm-secrets` plugin so encrypted values files live next to
plain values files in git.

| Secret | Storage | Decrypted by | Consumed by |
|---|---|---|---|
| Age private key | `/var/lib/sops-nix/key.txt` per host; `~/.config/sops/age/keys.txt` on the laptop. **Never in git.** | n/a (it *is* the key) | `sops-nix` at NixOS activation; `sops` CLI on the laptop |
| k3s join token | `secrets/chopper/k3s-token` (sops-encrypted in git) | `sops-nix` on the host | `services.k3s-cluster.tokenFile` (systemd) |
| Tailscale operator OAuth | `secrets/chopper/tailscale-operator-oauth` (sops in git) | `sops-nix` on the host → written to a runtime path → referenced by a `Secret` manifest in `services.k3s.manifests` | Tailscale operator pod |
| CNPG superuser + app DB password | **Generated by CNPG**, lives only in-cluster as `<cluster>-superuser` / `<cluster>-app` Secrets | n/a | CNPG pods; webservices read `<cluster>-app` once at deploy time |
| Barman Cloud S3 creds (off-site backups) | `k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml` (sops-encrypted `Secret` manifest) | `sops` CLI on the laptop at apply time (`sops --decrypt \| kubectl apply -f -`) | CNPG `ObjectStore` |
| Helm chart values containing secrets | `k8s/apps/<chart>/secrets.yaml` (sops-encrypted) | `helm-secrets` plugin via `helmfile` | Helm at install/upgrade time |
| Webservice connection string | Constructed from `<cluster>-app` Secret + `pg-rw.<tailnet>.ts.net` | out-of-scope for this repo | Cloud webservices |

Key rules:

- **Plaintext Secret manifests never enter git, not even temporarily.**
  Every file matching `k8s/**/secrets/*.enc.yaml` and
  `k8s/**/secrets.yaml` is sops-encrypted by `.sops.yaml` rules.
- **Bootstrap operator secrets** (Tailscale OAuth) flow through
  `sops-nix` because the operator must come up before any human runs
  `helmfile`. They become real `Secret` objects via
  `services.k3s.manifests` reading a runtime path written by
  `sops-nix`, **never** a Nix-store path (which is world-readable).
- **Iterative cluster secrets** (Barman S3 creds, future app secrets)
  flow through the laptop: `sops` decrypts, `kubectl`/`helmfile`
  applies. Cluster nodes don't need decrypt keys for these.
- **CNPG-managed secrets** are the safest — we don't supply them at
  all; CNPG generates them inside the cluster. Webservices fetch the
  app DB password once via `kubectl get secret <cluster>-app` at
  deploy time.
- **`.sops.yaml`** gets a new creation rule: files under
  `k8s/**/*.enc.yaml` and `k8s/**/secrets.yaml` are encrypted to the
  laptop user's age key + each cluster member host's age key (so the
  host can decrypt OAuth-style secrets surfaced via `sops-nix`).
  `secrets/<host>/*` rules from M7 are unchanged.

### 7.5 Repository layout additions

```
k8s/
├── README.md
├── helmfile.yaml              # pins CNPG operator + future charts
├── apps/
│   ├── cnpg-operator/         # values.yaml + secrets.yaml (sops)
│   └── kube-prometheus-stack/ # optional, later
├── clusters/
│   └── chopper/
│       ├── kustomization.yaml
│       ├── cnpg-cluster.yaml          # Postgres Cluster CR
│       ├── cnpg-pooler.yaml           # PgBouncer in front of -rw
│       ├── cnpg-backup.yaml           # ScheduledBackup + ObjectStore
│       ├── tailscale-pg-service.yaml  # tailscale LB exposing the pooler
│       └── secrets/
│           └── cnpg-backup-s3.enc.yaml  # sops-encrypted Secret
└── docs/
    └── runbooks/
        ├── failover.md
        ├── restore-pitr.md
        └── add-node.md
modules/services/k3s.nix       # NixOS module wrapping services.k3s + charts
profiles/k3s-node.nix          # role consumed via metadata.roles = [ "k3s" ]
secrets/chopper/k3s-token                       # sops, NixOS-side
secrets/chopper/tailscale-operator-oauth        # sops, NixOS-side
docs/k3s-cnpg.md               # architecture + 2-node trap warning
```

The **`Justfile`** grows:

- `just k8s-apply`     — `helmfile sync` + `kubectl apply -k k8s/clusters/chopper`, with `sops`-decrypted Secret manifests piped in.
- `just k8s-diff`      — `helmfile diff` + `kubectl diff -k ...` for preview.
- `just k8s-edit-secret <path>` — wrapper around `sops <path>`.

### 7.6 Stable Postgres URL — how it survives node loss

1. Webservice connects to `pg-rw.<tailnet>.ts.net:5432`.
2. That hostname is owned by a Tailscale operator-managed device (a
   `StatefulSet` of ts-proxy pods, replicas ≥ 2 once we have ≥ 2 nodes,
   with pod anti-affinity).
3. The ts-proxy forwards to the in-cluster Service `cnpg-cluster-rw`.
4. CNPG's `-rw` Service always points at the **current primary** pod.
5. If the primary pod / its node dies:
   - CNPG promotes a synchronous replica (RPO ≈ 0).
   - Service endpoints update within seconds.
   - Existing webservice TCP connections drop; the webservice must use a
     connection pool that retries (PgBouncer in front of `-rw` smooths
     this — short-lived backend connections, long-lived frontend).
6. If the ts-proxy pod's node dies, k8s reschedules it on the surviving
   node; the MagicDNS name is unchanged.
7. **Caveat:** if chopper is the *only* node, step 5 cannot save us — the
   cluster is down until chopper returns. This is why the 3rd quorum
   node + a 2nd workload node are required for the "survives any one
   host" promise. The doc must say this plainly.

### 7.7 Optional: PgBouncer in front

CNPG ships a `Pooler` CRD. Putting a transaction-mode PgBouncer in front
of `-rw` (and a separate one in front of `-ro`) gives:
- faster reconnect during failover,
- connection multiplexing for cloud webservices that may not pool well,
- a separate place to terminate TLS if we later want client-cert auth.

The Tailscale Service then targets the `Pooler` Service instead of
`-rw` directly.

### 7.8 What we are explicitly **not** doing

- **No GitOps controller** (Argo CD / Flux). One operator, one cluster;
  the reconcile loops we need already exist (CNPG, Tailscale, OpenEBS).
- **No Sealed Secrets** — it would create a second key-management
  system parallel to sops/age, with a separate disaster-recovery
  story (lose the controller key → every sealed secret in git is
  permanently undecryptable).
- **No External Secrets Operator / Vault / 1Password backend** —
  overkill for a homelab cluster; sops handles it.
- **No `kubenix` / Nix-as-Kubernetes-DSL** — we keep manifests as YAML
  so every kubectl tutorial / `kubectl explain` / Stack Overflow
  answer applies as written.
- No public ingress. Postgres is **never** reachable off the tailnet.
- No Longhorn / Ceph / Mayastor — overkill for two laptops, and CNPG
  already replicates.
- No HAProxy/keepalived VIP — the Tailscale operator replaces this.
- No bare-metal Patroni — CNPG is the chosen abstraction.
- No multi-cluster federation — single cluster, multiple nodes.

---

## 8. Percona XtraDB Cluster (PXC) — MySQL on k3s

This section captures the design for running **Percona XtraDB Cluster (PXC)**
on the same `glug-infra` k3s cluster, alongside the existing CNPG PostgreSQL
deployment. PXC provides **synchronous multi-master MySQL replication** via
Galera, managed by the Percona Operator for MySQL.

### 8.1 Goals & constraints

- **Same cluster** as CNPG — shared k3s, shared ZFS pool, shared Tailscale
  operator. No second cluster.
- **Workload:** MySQL 8.0 via Percona XtraDB Cluster (Galera-based
  synchronous replication).
- **Consumers:** webservices in the cloud, connected over the tailnet at
  `mysql-rw.<tailnet>.ts.net:3306`.
- **HA semantics:** identical to CNPG — phase 1 (single node) = no HA;
  phase 2+ = pods spread across nodes.

### 8.2 Topology decisions

| Decision | Choice | Rationale |
|---|---|---|
| Operator | **Percona Operator for MySQL (PXC)** 1.19.x | Kubernetes-native, Helm-deployable, manages Galera lifecycle, HAProxy, backups. |
| MySQL flavour | **Percona XtraDB Cluster 8.0** | Galera-based synchronous replication, battle-tested. |
| Proxy | **HAProxy** (operator-managed) | Simpler than ProxySQL; routes writes to the current Galera writer node. |
| Storage | **OpenEBS ZFS LocalPV** with `recordsize=16k` | Matches InnoDB's 16KB page size (vs 8k for PostgreSQL). |
| Backup | **Percona XtraBackup → S3** | Scheduled daily at 03:00 UTC, 14-day retention. |
| Tailscale endpoint | `mysql-rw.<tailnet>.ts.net:3306` | Same pattern as `pg-rw` — LoadBalancer Service with `loadBalancerClass: tailscale`. |
| Namespace | `pxc-clusters` (kustomize) / `pxc-system` (helmfile) | Mirrors the `cnpg-clusters` / `cnpg-system` split. |

### 8.3 ZFS optimisation for InnoDB

The default `zfs-localpv` StorageClass (8k recordsize) is tuned for
PostgreSQL. MySQL/InnoDB uses **16KB pages**, so a second StorageClass
`zfs-localpv-16k` is bootstrapped in `modules/services/k3s.nix`:

- `recordsize=16k` — 1:1 mapping between InnoDB pages and ZFS records;
  eliminates read/write amplification.
- `compression=zstd` — same as the 8k class.
- Same pool (`rpool/openebs`) — OpenEBS applies the SC's recordsize to
  each child dataset it creates.

InnoDB configuration (in the PXC CR via `pxc.configuration`):

- `innodb_doublewrite=0` — ZFS is copy-on-write; the doublewrite buffer
  is redundant and wastes IOPS.
- `innodb_flush_method=O_DIRECT` — bypass the Linux page cache; let ZFS
  ARC handle caching.
- `innodb_flush_neighbors=0` — NVMe doesn't benefit from sequential
  neighbour flushing.
- `innodb_io_capacity=2000` / `innodb_io_capacity_max=4000` — NVMe can
  handle more IOPS than spinning rust defaults.

### 8.4 NixOS integration points

- **New bootstrap StorageClass** in `modules/services/k3s.nix`:
  `zfs-localpv-16k` (NOT the default, must be explicitly requested).
- No additional sops secrets needed — the PXC operator generates its own
  internal secrets (root password, replication creds). S3 backup creds
  are handled via `helm-secrets` (same as CNPG).

### 8.5 Repository layout additions

```
k8s/
├── apps/
│   ├── pxc-operator/
│   │   ├── values.yaml          # PXC operator Helm values
│   │   └── secrets.yaml         # sops-encrypted (empty by default)
│   └── mysql/
│       ├── values.yaml          # PXC cluster + HAProxy + backups
│       └── secrets.yaml         # sops-encrypted S3 creds
├── clusters/
│   └── glug-infra/
│       ├── pxc/
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml           # pxc-clusters + PSA restricted
│       │   ├── networkpolicy.yaml       # default-deny + HAProxy + PXC rules
│       │   └── tailscale-mysql-service.yaml  # Tailscale LB: mysql-rw
│       └── monitoring/
│           ├── pxc-cluster-servicemonitor.yaml
│           ├── pxc-haproxy-servicemonitor.yaml
│           └── pxc-prometheusrules.yaml
modules/services/k3s.nix         # + zfs-localpv-16k StorageClass
```

### 8.6 Stable MySQL URL — how it survives node loss

1. Webservice connects to `mysql-rw.<tailnet>.ts.net:3306`.
2. That hostname is owned by a Tailscale operator-managed device.
3. The ts-proxy forwards to the in-cluster `mysql-haproxy` Service.
4. HAProxy routes to the current Galera writer node.
5. If the writer pod / its node dies:
   - Galera promotes another node to writer (automatic, RPO = 0 for
     committed transactions thanks to synchronous replication).
   - HAProxy detects the failure and re-routes within seconds.
6. Same single-node caveat as CNPG: if chopper is the only node, the
   cluster is down until chopper returns.

### 8.7 Monitoring

- **mysqld_exporter** sidecar on each PXC pod (port 9104) → scraped by
  a standalone ServiceMonitor in kustomize.
- **HAProxy stats** (port 33062) → scraped by a separate ServiceMonitor.
- **PrometheusRules** for Galera health (wsrep_ready, cluster size,
  flow control), slow queries, and PVC capacity.

### 8.8 Helmfile releases

| # | Release | Chart | Version | Namespace |
|---|---|---|---|---|
| 4 | `pxc-operator` | `percona/pxc-operator` | `1.19.1` | `pxc-system` |
| 5 | `mysql` | `percona/pxc-db` | `1.19.2` | `pxc-clusters` |

Both depend on `monitoring/kube-prometheus-stack` (for CRDs). `mysql`
also depends on `pxc-system/pxc-operator`.

### 8.9 Day-2 operations

```sh
just k8s::pxc-status          # show PerconaXtraDBCluster status
just k8s::pxc-describe        # detailed cluster description
just k8s::pxc-operator-logs   # tail operator logs
just k8s::pxc-primary-logs    # tail writer node logs
just k8s::pxc-haproxy-logs    # tail HAProxy logs
just k8s::pxc-pods            # list all PXC pods
just k8s::pxc-backup-list     # list backup objects
just k8s::pxc-backup-now      # trigger on-demand backup
just k8s::pxc-shell           # MySQL CLI via HAProxy
```
