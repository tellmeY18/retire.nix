# ROADMAP.md — Path to a Truly Reproducible Multi-System Nix Config

> **Status: All 16 milestones (M0–M15) complete as of initial cleanup pass.**
> Active workstream: **M16–M22 — Production-grade k3s + CloudNativePG** (see
> [`CLAUDE.md` §7](./CLAUDE.md#7-production-grade-k3s--cloudnativepg-architecture)).
> Cross-cutting backlog items remain for ongoing maintenance.

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

- [x] Tag the current commit as `pre-cleanup-baseline`.
- [x] Capture current build outputs:
  - [x] `nix build .#darwinConfigurations.Vysakhs-MacBook-Pro.system` (on mac)
  - [x] `nix build .#nixosConfigurations.chopper.config.system.build.toplevel`
  - [x] `nix build .#homeConfigurations."mathewalex@Vysakhs-MacBook-Pro".activationPackage`
  - [x] `nix build .#homeConfigurations."vysakh@chopper".activationPackage`
- [x] Add a `flake check` smoke target (even if it only evaluates inputs).
- [x] Snapshot `flake.lock` and note current input revisions in
      `docs/baselines/<date>.md`.
- [x] Add this `ROADMAP.md` and `CLAUDE.md` to the repo root. ✅

**Exit criteria:** all four artifacts build; baseline tag exists.

---

## Milestone 1 — Documentation Reality Check  ·  📚 🧹  ·  Effort: S

Goal: stop lying to readers (and to ourselves).

- [x] Rewrite `README.md`:
  - [x] Remove references to `overlays/`, `scripts/`, `packages/chopper/`,
        `modules/esp.nix`.
  - [x] Document the actual structure (mirror `CLAUDE.md` §1).
  - [x] Document supported hosts and how to build each.
- [x] Rewrite `home/README.md`:
  - [x] Replace `common.nix` / `darwin.nix` / `chopper.nix` references with
        the real `home/{darwin-home,linux-home}.nix` entry points and
        `home/{common,darwin,chopper}/` trees.
- [x] Add `CONTRIBUTING.md` skeleton (formatting, commit style, "how to add
      a host" pointer).

**Exit criteria:** every path mentioned in markdown exists in the repo.

---

## Milestone 2 — Dev Shell, Formatter, Lints  ·  🧪 🧹  ·  Effort: M

Goal: any contributor can run a single command and have the right tools.

- [x] Add `devShells.<system>.default` providing:
      `nixpkgs-fmt`, `treefmt`, `statix`, `deadnix`, `nil`, `nixd`,
      `sops`, `age`, `nh`, `git`, `just` (optional).
- [x] Add `treefmt.nix` (or `treefmt-nix` flake-module) covering:
      `*.nix` → `nixpkgs-fmt`, `*.md` → `mdformat`, `*.sh` → `shfmt`.
- [x] Set `formatter.<system> = treefmt`.
- [x] Run `nix fmt` once across the whole tree; commit the noise separately.
- [x] Run `statix check` and `deadnix` once; fix or `# noqa`-justify
      remaining hits.
- [x] Add a `Justfile` (or `flake.nix` apps) for common chores:
      `just fmt`, `just check`, `just build-chopper`, `just build-mac`.

**Exit criteria:** `nix develop` enters a shell with all tools;
`nix fmt && nix flake check` is green.

---

## Milestone 3 — `lib/` factories & flake refactor  ·  🧹  ·  Effort: M

Goal: `flake.nix` becomes a thin orchestrator, not a config dump.

- [x] Create `lib/default.nix` exposing:
  - [x] `mkHost { hostname, system, modules ? [], extraModules ? [] }`
  - [x] `mkDarwinHost { ... }`
  - [x] `mkHome { username, hostname, system, modules ? [] }`
  - [x] `forAllSystems` helper (replace ad-hoc `flake-utils.lib.eachSystem`).
- [x] Move the duplicated Fenix/Rust block into `modules/dev/rust.nix`;
      import it from both hosts.
- [x] Move the `nix-homebrew` config block from `flake.nix` into
      `hosts/darwin/homebrew.nix` (imported by `hosts/darwin/configuration.nix`).
- [x] Replace explicit `darwinConfigurations` and `nixosConfigurations`
      bodies with calls to the new factories.
- [x] Make the systems list (`["aarch64-darwin" "x86_64-linux"]`) the single
      source of truth — derive it from the discovered hosts where possible.
- [x] Decide on `cook` input: restore with a `lib.mkIf` toggle **or** delete.

**Exit criteria:** `flake.nix` is < 100 lines; both hosts still build;
`nix flake check` green.

---

## Milestone 4 — Per-Host Metadata & Auto-Discovery  ·  🧹  ·  Effort: M

Goal: adding a host = create a directory.

- [x] Define schema for `hosts/<name>/metadata.nix`:
      `{ hostname, system, hostId?, timezone, users, roles, stateVersion }`.
- [x] Migrate `chopper` and `Vysakhs-MacBook-Pro` to the schema.
- [x] Implement `lib.discoverHosts ./hosts` that scans for
      `metadata.nix` files and returns the appropriate
      `nixosConfigurations` / `darwinConfigurations`.
- [x] Same idea for `homeConfigurations` keyed `${user}@${hostname}`.
- [x] Add `hosts/template/` (NixOS) and `hosts/template-darwin/` examples
      that build but do nothing harmful (no real users / secrets).
- [x] Update `docs/add-a-host.md`.

**Exit criteria:** removing a host directory is the only thing needed to
remove a host; adding one needs no `flake.nix` edits.

---

## Milestone 5 — Decompose `hosts/chopper/default.nix`  ·  🧹  ·  Effort: L

Goal: kill the 350-line god-module.

- [x] Create `hosts/chopper/parts/`:
  - [x] `boot.nix` — bootloader + ZFS overrides.
  - [x] `network.nix` — networking, firewall, DNS.
  - [x] `power.nix` — TLP + logind.
  - [x] `display.nix` — greetd, sway, polkit, pam.
  - [x] `virtualisation.nix` — docker, podman.
  - [x] `programs.nix` — zsh/git/tmux/nh/lazygit (system-level only;
        prefer Home Manager).
- [x] Move all `services.*` blocks into proper modules under
      `modules/services/*` with `options.<svc>.enable`:
  - [x] `tailscale.nix`
  - [x] `nextcloud.nix` (already exists — convert to optionised module)
  - [x] `cloudflared.nix`
  - [x] `openssh.nix`
  - [x] `zfs-maintenance.nix`
- [x] `hosts/chopper/configuration.nix` becomes ~20 lines: imports +
      `metadata`.

**Exit criteria:** no host file exceeds ~120 lines; module list in
`hosts/chopper/configuration.nix` reads like a table of contents.

---

## Milestone 6 — Users as First-Class Citizens  ·  🧹 🔒  ·  Effort: M

Goal: no personal identity leaks outside `users/*`.

- [x] Create `users/<name>.nix` for each user:
      `{ username, fullName, email, sshKeys, shell, extraGroups }`.
- [x] Create `lib.mkUser` that consumes that schema and produces both
      `users.users.<name>` (NixOS/Darwin) and HM `home.*` defaults.
- [x] Migrate `vysakh`, `mathewalex`, `root` (keys only) to this scheme.
- [x] Make git `user.name` / `user.email` come from the user record
      (in HM `programs.git`).

**Exit criteria:** grepping for `vysakhpr218@gmail.com` returns hits only
in `users/vysakh.nix`.

---

## Milestone 7 — Secrets via sops-nix  ·  🔒 📚  ·  Effort: L

Goal: kill every `/home/vysakh/<secret>` reference.

- [x] Generate per-host age keys (`age-keygen` on each host);
      document in `docs/secrets.md`.
- [x] Add `.sops.yaml` with creation rules per host.
- [x] Create `secrets/` with encrypted files:
  - [x] `secrets/chopper/tailscale-authkey`
  - [x] `secrets/chopper/nextcloud-admin-pass`
  - [x] `secrets/chopper/cloudflared/<uuid>.json`
- [x] Wire `sops.secrets.*` into:
  - [x] `services.tailscale.authKeyFile`
  - [x] `services.nextcloud.config.adminpassFile`
  - [x] `services.cloudflared.tunnels.*.credentialsFile`
- [x] Remove the `environment.etc."tailscale/auth.key".source =
      "/home/vysakh/tail.key"` hack.
- [x] Document bootstrap: "how to provision a new host given the age key".

**Exit criteria:** `git grep '/home/vysakh/'` returns 0 hits; a fresh
machine can be brought up given only this repo + an age key.

---

## Milestone 8 — Home Manager Cleanup  ·  🧹  ·  Effort: M

Goal: stop maintaining parallel trees.

- [x] Audit duplicates between `home/common/` and `home/{darwin,chopper}/`:
  - [x] `kitty` — collapse to one module gated by `pkgs.stdenv.isDarwin`.
  - [x] `zsh` — same treatment.
- [x] Convert `home/common/git` to read identity from the active user
      record (Milestone 6).
- [x] Re-examine `home/common/packages` — split into role-based bundles
      (`cli`, `dev-rust`, `dev-web`, `media`, etc.) so hosts opt-in.
- [x] Document the HM module hierarchy in `home/README.md`.

**Exit criteria:** no two files configure the same program with different
settings.

---

## Milestone 9 — Profiles / Roles  ·  🧹  ·  Effort: M

Goal: composable host archetypes.

- [x] Create `profiles/`:
  - [x] `profiles/base.nix` — locale, nix settings, common pkgs.
  - [x] `profiles/laptop.nix` — TLP, lid handling, wifi.
  - [x] `profiles/server.nix` — headless, no GUI, journald tuning.
  - [x] `profiles/zfs.nix` — replaces `modules/zfs.nix`.
  - [x] `profiles/wayland.nix` — sway/greetd/portals.
  - [x] `profiles/dev.nix` — rust, docker, lazygit.
- [x] Each host's `metadata.roles` selects which profiles get imported.
- [x] Migrate `chopper` to declare `roles = [ "laptop" "server" "zfs"
      "wayland" "dev" ]`.

**Exit criteria:** the `template/` host can be turned into a "server"
host by toggling roles only.

---

## Milestone 10 — Packages & Overlays Unification  ·  🧹  ·  Effort: S

- [x] Create `overlays/default.nix` aggregating all overlays.
- [x] Move `neondb` callPackage out of `flake.nix` into
      `overlays/neondb.nix`.
- [x] Audit `packages/chopper/` and `packages/darwin/` — convert to
      `packages.<system>.<name>` outputs.
- [x] Either populate `packages/default.nix` meaningfully or delete it.

**Exit criteria:** `nix build .#<pkg>` works for every custom package;
`flake.nix` no longer contains overlay logic inline.

---

## Milestone 11 — CI & Caching  ·  🧪  ·  Effort: M

- [x] Add `.github/workflows/check.yml`:
  - [x] `nix flake check` on `ubuntu-latest` and `macos-latest`.
  - [x] `statix check` and `deadnix --fail`.
  - [x] `treefmt --fail-on-change`.
- [x] Add `.github/workflows/build.yml`:
  - [x] Build `nixosConfigurations.chopper` toplevel.
  - [x] Build `darwinConfigurations.Vysakhs-MacBook-Pro` system.
  - [x] Build both home configurations.
- [x] (Optional) Push to Cachix or self-hosted Attic.
- [x] Add status badges to `README.md`.

**Exit criteria:** PRs are blocked on red CI.

---

## Milestone 12 — Security Hardening Pass  ·  🔒  ·  Effort: M

- [x] SSH:
  - [x] Set `PermitRootLogin = "prohibit-password"` (or `no`); document.
  - [x] Confirm `PasswordAuthentication = false` everywhere.
- [x] Sudo: re-enable `wheelNeedsPassword = true` unless there is a
      written justification in `docs/security.md`.
- [x] Firewall: bind Nextcloud / Conduit / Care to `127.0.0.1` and front
      via Cloudflared; close TCP `4000`, `80`, `443` on the public iface.
- [x] Replace `permittedInsecurePackages = [ "conduwuit-0.4.6" ]` with a
      tracked upgrade or remove the service.
- [x] Document the threat model briefly in `docs/security.md`.

**Exit criteria:** `nmap` against the host shows only the intended ports;
`docs/security.md` exists.

---

## Milestone 13 — Stable Channel & State Version Policy  ·  🧹 📚  ·  Effort: S

- [x] Add a `nixpkgs-stable` input (matching the current NixOS release).
- [x] Decide which services pin to stable (Nextcloud, Postgres, ZFS userland
      candidates) and wire them via `pkgs-stable` from a small overlay.
- [x] Centralise `system.stateVersion` and `home.stateVersion` in
      `lib/stateVersion.nix` with a documented upgrade policy.

**Exit criteria:** `docs/channels.md` explains why a given service tracks
stable vs unstable.

---

## Milestone 14 — Second Real Host (Validation)  ·  🧪  ·  Effort: M

Goal: prove the abstractions work.

- [x] Add a real (or VM) second NixOS host using only:
      `mkdir hosts/<name> && $EDITOR metadata.nix` plus a hardware import.
- [x] Build it in CI.
- [x] Document the journey in `docs/add-a-host.md` with screenshots/diff.

**Exit criteria:** the new host builds without touching any file outside
`hosts/<name>/` and `secrets/<name>/`.

---

## Milestone 15 — Final Polish  ·  📚 🧹  ·  Effort: S

- [x] Add Mermaid diagram of module composition to `README.md`.
- [x] Add `docs/bootstrap-darwin.md`, `docs/bootstrap-nixos.md`.
- [x] Re-read every `TODO`/`FIXME`/commented block; resolve or file an issue.
- [x] Tag `v1.0-reproducible` once the Definition of Done in `CLAUDE.md` §6
      is met.

---

# Phase 2 — Production-Grade k3s + CloudNativePG

> Reference design: [`CLAUDE.md` §7](./CLAUDE.md#7-production-grade-k3s--cloudnativepg-architecture).
> Goal: a Postgres URL on the tailnet (`pg-rw.<tailnet>.ts.net:5432`) that
> webservices in the cloud can rely on, surviving any single node failure
> once ≥ 3 nodes are joined.

**Phase rule:** every milestone leaves the cluster in a working state.
We deliberately stand the cluster up on `chopper` alone first (no HA),
then layer redundancy. Do not skip M16/M17 even though they don't add HA —
they set the topology that later milestones rely on.

---

## Milestone 16 — k3s NixOS module + single-node bring-up on chopper  ·  🧹 🔒  ·  Effort: L

Goal: a reproducible single-node k3s server on `chopper`, all traffic on
`tailscale0`, kubeconfig usable from the laptop.

- [ ] Add `modules/services/k3s.nix` with the option schema in
      `CLAUDE.md` §7.4. Defaults: `--disable=traefik,servicelb`,
      `--flannel-iface=tailscale0`, `--node-ip=<tailscale4>`,
      `--advertise-address=<tailscale4>`, `--tls-san=<host>.ts.net`.
- [ ] Add `profiles/k3s-node.nix`; add `"k3s"` to `chopper`'s
      `metadata.roles`.
- [ ] ZFS datasets: `rpool/k3s` (→ `/var/lib/rancher/k3s`) and
      `rpool/openebs` (for ZFS LocalPV) created via disko or
      `services.zfs.datasets`. Tuned per §7.4.
- [ ] Sops secret `secrets/chopper/k3s-token` consumed by
      `services.k3s-cluster.tokenFile` (random 64-byte token; same value
      will be reused when peers join).
- [ ] Firewall: open `6443/tcp`, `8472/udp` (flannel), `10250/tcp`,
      `2379-2380/tcp` (etcd) **only on `tailscale0`**.
- [ ] Wait condition on `tailscaled.service` so k3s never starts before
      the tailnet IP is up (`systemd` `After=`/`Requires=`).
- [ ] `kubectl` + `helm` + `cmctl` + `k9s` added to `profiles/k3s-node.nix`'s
      system packages and `home/common/packages/dev-k8s.nix` (new bundle).
- [ ] Smoke test: `kubectl get nodes` shows `chopper Ready` with
      `INTERNAL-IP` = tailscale IP.

**Exit criteria:** `nixos-rebuild switch` brings k3s up; node is Ready;
no k3s ports are reachable on the public interface (`nmap` from off-net).

---

## Milestone 17 — Bootstrap operators via Nix + manifest layout for the rest  ·  🧹 🔒  ·  Effort: M

Goal: every "install once, never touch" operator comes back automatically
after a reboot via NixOS; everything iterative lives under `k8s/` and
is applied with `helmfile` + `kubectl` from the laptop. **No Argo CD,
no Flux, no Sealed Secrets, no External Secrets Operator.**

- [ ] `services.k3s.charts.openebs-zfs-localpv` declared in NixOS:
      pinned chart version, values point at `rpool/openebs`, default
      `StorageClass` `zfs-localpv` with `volumeBindingMode: WaitForFirstConsumer`.
- [ ] `services.k3s.charts.tailscale-operator` declared in NixOS,
      consuming the OAuth client ID/secret rendered into a `Secret`
      object via `services.k3s.manifests` from a sops-decrypted runtime
      path (NOT a Nix-store path — see `CLAUDE.md` §7.4a).
- [ ] Sops secret `secrets/chopper/tailscale-operator-oauth` added.
- [ ] `.sops.yaml` extended with creation rules for `k8s/**/*.enc.yaml`
      and `k8s/**/secrets.yaml` (encrypted to laptop user + each
      cluster member host).
- [ ] `k8s/` directory created per `CLAUDE.md` §7.5 with
      `helmfile.yaml` pinning chart versions for CNPG (and any future
      iterative charts).
- [ ] `helm-secrets` plugin added to the dev shell + `profiles/k3s-node.nix`
      so `helmfile sync` transparently decrypts `secrets.yaml`.
- [ ] `Justfile` recipes:
      - [ ] `just k8s-apply` — `helmfile sync` + `kubectl apply -k k8s/clusters/chopper`,
            piping `sops --decrypt` for any `*.enc.yaml` Secret manifests.
      - [ ] `just k8s-diff` — dry-run preview.
      - [ ] `just k8s-edit-secret <path>` — wraps `sops`.
- [ ] Verify: a throwaway `PVC` of class `zfs-localpv` binds and a
      busybox pod writes to it; ZFS shows a new dataset under
      `rpool/openebs`. `kubectl get pods -n tailscale` shows the
      operator Running.

**Exit criteria:** rebooting `chopper` brings the cluster back with
OpenEBS + Tailscale operator already healthy, no human in the loop;
`just k8s-apply` is idempotent and green from a clean checkout.

---

## Milestone 18 — CNPG operator + first Cluster (single node)  ·  🧹 🔒  ·  Effort: L

Goal: a working Postgres reachable in-cluster, ready for HA topology.

- [ ] `k8s/apps/cnpg-operator/` chart pinned via `helmfile.yaml`
      (specific minor version + chart digest for reproducibility).
- [ ] `k8s/clusters/chopper/cnpg-cluster.yaml`:
      `instances: 3`, `storage.storageClass: zfs-localpv`,
      `postgresql.synchronous.method: any`,
      `postgresql.synchronous.number: 1`,
      pod anti-affinity `preferredDuringScheduling` on hostname
      (will become `required` in M21 once ≥ 2 nodes).
- [ ] Bootstrap database + app role declared in the `Cluster` spec.
      **No app password supplied** — CNPG generates `<cluster>-app` and
      `<cluster>-superuser` Secrets in-cluster (§7.4a).
- [ ] `cnpg-pooler.yaml`: `Pooler` (PgBouncer, transaction mode) in
      front of the `-rw` Service.
- [ ] Verify: `psql` from a debug pod (using `<cluster>-app`) hits
      both `<cluster>-rw` and the pooler Service; `kubectl cnpg status`
      is green; deleting the primary pod fails over within ~10s.

**Exit criteria:** Postgres reachable in-cluster with replication
healthy; primary pod deletion triggers clean failover.

---

## Milestone 19 — Tailscale-typed Service → stable Postgres URL  ·  🧹 🔒  ·  Effort: M

Goal: cloud webservices get a forever-stable hostname.

*(The Tailscale operator itself was already bootstrapped in M17.
This milestone only declares the Service that exposes Postgres.)*

- [ ] `k8s/clusters/chopper/tailscale-pg-service.yaml`: `Service` of
      type `LoadBalancer` with `loadBalancerClass: tailscale` and
      annotation `tailscale.com/hostname: pg-rw`, target = the
      `Pooler` Service from M18.
- [ ] Tailscale ACL update (out-of-band, documented in
      `docs/k3s-cnpg.md`): `tag:k8s` accepts from `tag:cloud-webservice`
      on `:5432` only.
- [ ] Verify from a cloud tailnet member:
      `psql "postgresql://app@pg-rw.<tailnet>.ts.net:5432/app"` works;
      kill the primary pod → connection retries succeed within ~10s.

**Exit criteria:** the documented Postgres URL works from at least one
remote tailnet member; primary pod failover does not change it.

---

## Milestone 20 — Off-site backups + DR runbook  ·  🔒 📚  ·  Effort: M

Goal: survive losing every laptop.

- [ ] Provision an off-site S3 bucket (Backblaze B2 or Cloudflare R2).
- [ ] Credentials stored as a sops-encrypted `Secret` manifest at
      `k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml`,
      applied by `just k8s-apply` via `sops --decrypt | kubectl apply -f -`.
- [ ] `cnpg-backup.yaml`: `ObjectStore` + `ScheduledBackup` (daily base
      + continuous WAL archiving), retention = 14 days.
- [ ] Optional warm tier: a second `ObjectStore` pointing at the
      existing Garage on `chopper` for fast in-network restores.
- [ ] Document and rehearse:
      - [ ] `docs/runbooks/restore-pitr.md` — PITR into a fresh `Cluster`.
      - [ ] `docs/runbooks/failover.md` — manual switchover.
      - [ ] Quarterly restore drill checklist.
- [ ] Verify: spin up a `Cluster` with `bootstrap.recovery` from the
      off-site object store in a scratch namespace; data is intact.

**Exit criteria:** a documented, tested PITR succeeds end-to-end from
the off-site bucket alone.

---

## Milestone 21 — Second node + true pod-anti-affinity  ·  🧹  ·  Effort: M

Goal: pods spread across hosts; primary failover survives one node.

- [ ] Add `hosts/<second-laptop>/` (real or VM) with the same
      `"k3s"` role and `services.k3s-cluster.role = "server"`.
- [ ] Joins via `tokenFile` + `serverAddr = https://chopper:6443`
      (Tailscale FQDN preferred).
- [ ] Flip CNPG `affinity.podAntiAffinityType` to
      `requiredDuringSchedulingIgnoredDuringExecution` on
      `kubernetes.io/hostname`.
- [ ] Tailscale operator: scale ts-proxy `replicas: 2` with pod
      anti-affinity so the egress survives one node.
- [ ] Add admin kubeconfig with both apiservers in `clusters[].server`
      (round-robin) so `kubectl` survives chopper being down.
- [ ] **Document the 2-node trap loudly** in `docs/k3s-cnpg.md`:
      losing either node makes etcd lose quorum; the cluster is
      read-only until the third node arrives. M22 fixes this.
- [ ] Verify: cordon+drain chopper; `pg-rw` URL still serves writes.

**Exit criteria:** with both nodes up, killing chopper's k3s
(`systemctl stop k3s`) keeps the Postgres URL writable until etcd
quorum is lost. Time-to-failover ≤ 30s for the PG primary.

---

## Milestone 22 — Quorum tiebreaker + true "survives one host" SLO  ·  🧹 🔒  ·  Effort: M

Goal: the cluster (and Postgres URL) survive any one host going away.

- [ ] Provision a tiny always-on tailnet node (Pi / cheap VPS / home VM)
      as `hosts/<tiebreaker>/` with role `"k3s"` and
      `services.k3s-cluster.role = "quorum"`:
      - taints: `node-role.kubernetes.io/control-plane:NoSchedule`,
        `quorum-only=true:NoExecute`.
      - no OpenEBS pool; minimal disk.
- [ ] CNPG `Cluster` `nodeSelector`/`tolerations` exclude
      `quorum-only` nodes; ts-proxy pods likewise.
- [ ] System Upgrade Controller installed and pinned to a k3s channel.
- [ ] `kube-prometheus-stack` (lightweight values) + alerts on:
      etcd quorum loss, CNPG replication lag, PVC fill, node NotReady.
- [ ] Chaos drill: power off chopper for 10 minutes; webservices keep
      working. Power off the second laptop; webservices keep working.
      Power off the tiebreaker; cluster goes read-only (expected).
- [ ] Capture results + RTO/RPO in `docs/k3s-cnpg.md`.

**Exit criteria:** the documented SLO holds: any one of the three
nodes can be powered off and the Postgres URL keeps serving reads
and writes within the documented RTO (target: ≤ 60s).

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
8. **M16–M19**: stand up k3s + CNPG on chopper alone, expose stable
   Postgres URL over Tailscale (no HA yet, but topology is correct).
9. **M20**: off-site backups — the only thing that protects against
   losing every laptop. Do not defer.
10. **M21–M22**: add the second laptop, then the quorum tiebreaker, to
    finally honour "survives any one host".
