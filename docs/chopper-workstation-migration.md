# Chopper workstation conversion and Darwin retirement

Status: plan only. Based on repository configuration inspected on 2026-11-12;
live placement, disk usage, backups, and hardware still need verification.

## Target

| Machine | Final responsibility |
| --- | --- |
| Chopper | Primary daily-driver NixOS laptop, Sway/Wayland, development, repository checkout, secrets administration, and fleet deployment. No k3s or always-on application dependency. |
| C3po | Always-on k3s storage worker: application databases, object storage, persistent volumes, and any required server duties leaving Chopper. |
| Kenobi | Existing k3s control plane and compute/ingress. Its own etcd/control-plane state remains local and backed up. |
| Other workers | Existing compute roles; remove dependencies on Chopper's former server role. |
| Darwin Mac | Retired after daily-driver and administration acceptance checks. |
| OpenClaw/Signal gateway | Decommissioned. Configuration recoverable from repository history; no replacement deployment. |

User-confirmed choices: Sway/Wayland, no k3s on Chopper, persistence on C3po,
and OpenClaw retirement. Use the existing `vysakh` account and
`/home/vysakh/nix-config` on Chopper unless a different local identity is needed.
Personal working files belong on Chopper with an independent backup.

Interpretation of “all persistence”: consolidate durable **application** data on
C3po, including the MediaWiki database currently configured on Kenobi. Machine
identity, OS state, and Kenobi's etcd remain on their respective hosts. Inventory
rebuildable caches separately so they are not mistaken for authoritative data.

## Findings that determine the sequence

- Chopper and C3po are configured as **agents**; Kenobi is the sole configured
  server (`hosts/*/parts/k3s.nix`). Older three-server/HA comments are stale.
- OpenEBS ZFS LocalPV is node-local. Draining Chopper or changing a pod selector
  does not move its PVC data or PV topology.
- RustFS already has a Chopper primary, a C3po replica, an nginx front end, and
  `mc mirror --watch --overwrite --remove` from Chopper to C3po. The mirror must
  stop before C3po accepts independent writes.
- Ghost MySQL MGR has members on Chopper, C3po, and Kenobi. Removing Chopper
  changes quorum; simply deleting its pod is not a permanent migration design.
- PostgreSQL is configured with one instance. Its live node/PVC placement must
  be checked; there is no configured standby to assume can be promoted.
- MediaWiki MySQL uses `/var/lib/mysql-mediawiki` on Kenobi. Other Kenobi
  hostPaths include Ghost member C, Redis, OpenSearch, and wiki file caches.
- C3po's disk layout describes a single **238 GB SSD**. Existing claims include
  a 100 GiB RustFS replica; actual usage, ZFS reservations, and migration staging
  space decide feasibility. Historical configs document Wi-Fi/node instability.
- Chopper still advertises an exit node and its old pod subnet. Other hosts
  explicitly route that subnet through Chopper; R2D2 still points its agent at
  Chopper's obsolete API endpoint.
- Chopper's server power policy, SSH-only account setup, and missing Linux Home
  Manager configuration are not sufficient for a daily-driver graphical login.
- `.sops.yaml` comments disagree with its actual cluster-secret recipients
  (master, Chopper, Kenobi). Changing rules alone does not re-encrypt old files.

## P0 — Inventory, recovery copies, and capacity

Before changing services, record the live state in a private migration ledger:

1. List nodes/roles, pods with their nodes, all PVCs/PVs (including Released
   volumes), CSI volume handles, ZFSVolume objects, reclaim policies, node
   affinity, StorageClasses, and pod disruption budgets. Map every volume to
   its application, source dataset/path, size, destination, and restore method.
1. Inspect Chopper and C3po: pool health, datasets/zvols/snapshots, free and
   reserved space, disk health, RAM/CPU pressure, swap, network throughput,
   failed services, enabled timers, and listeners. Inspect hostPaths and
   `/var/lib` beyond the manifests, including disabled legacy applications.
1. Inventory the Mac's repositories (including unpushed jj changes), documents,
   browser/password-manager data, SSH and signing keys, SOPS keys, cloud CLI
   credentials, kubeconfigs, developer databases/containers, and tool state.
   Inventory app needs rather than copying macOS binaries or caches.
1. Take application-consistent database backups, object-storage backups, a
   Kenobi etcd snapshot with the required server token, and ZFS snapshots of
   source volumes. Keep recovery copies off both Chopper and C3po; a second
   dataset on C3po is not an independent backup. Test representative restores.
1. Budget C3po for existing data + incoming data + temporary duplicate restores
   - retained snapshots + growth, with at least 20% pool headroom. Include
     database and monitoring RAM/IO load, not just PVC sizes. Prefer wired LAN;
     demonstrate stable connectivity under the expected transfer workload.

**Exit:** every persistent item has a disposition, restore tests pass, and C3po
has sufficient measured capacity and stability. Upgrade its storage/RAM/network
first if needed. No repartitioning or disko formatting is part of this migration.

## P1 — Retire OpenClaw

This can happen before the storage migration and reduces Chopper's workload.

- Preserve the pre-removal revision in durable remote repository history.
  Remove the gateway, Signal integration, Android TV integration owned by the
  gateway, tmpfiles ownership rule, Tailscale Serve unit, and dedicated packages
  from `hosts/chopper/parts/services.nix`.
- Remove OpenClaw secret declarations and encrypted secret entries, the
  insecure-package exception, `nix-openclaw` and its host module arguments,
  and the Signal-only overlay/pinned input when no remaining consumer needs it.
  Prune unused lock inputs without updating unrelated dependencies.
- Stop the running services and explicitly clear their persisted Tailscale Serve
  configuration. Removing the unit alone does not undo `tailscale serve --bg`.
- Revoke experiment-only API tokens and unlink the Signal bot device. Check
  shared-token consumers before revocation. Keep runtime conversations/device
  state in a private encrypted archive if wanted; they are not in Git history.
- Retire the experiment's active documentation/skill references with the code.
  Repository history is the archive; no dormant duplicate module is needed.

**Exit:** no gateway/Signal process or Serve endpoint remains, no active config
references the removed inputs, and the historical implementation is recoverable.

## P2 — Prepare C3po and move application data

Keep Chopper running k3s until every source volume is migrated and verified.
Cordon it to prevent new scheduling once destination capacity is ready; migrate
existing applications individually before a final drain. Preserve source PVs
with `Retain` before any PVC/controller replacement and record their identities.

Use the existing OpenEBS pools and storage classes on C3po. For each move: prepare
the destination, take a recovery copy, stop all writers (including jobs), perform
the final sync/restore, validate, switch clients, then reopen writes. Fence the
old instance so it cannot become a second writable primary.

| Data/service | Migration and acceptance |
| --- | --- |
| RustFS and all buckets | Reuse the C3po replica instead of allocating a second 100 GiB store. Quiesce every S3 writer, including app uploads, Attic pushes/GC, and backup jobs. Verify final object contents, deletions, bucket policies/CORS, credentials, and any versioning/lifecycle configuration; `mc mirror` is not proof of full metadata/version parity. Reconcile any replica-only writes before final mirroring. Stop the old mirror, point the existing stable proxy/services at C3po, then reopen writes. Test upload/download/delete and public access. Retire the Chopper StatefulSet, old upstream, and mirror only after verification. |
| PostgreSQL / CNPG | If already entirely on C3po, verify data and WAL PVs and keep them. Otherwise use supported CNPG replication/switchover or a tested backup restore onto new C3po-local data and WAL PVCs. Preserve roles, databases, extensions, and application endpoints. Check fresh writes and backup/WAL archiving after cutover. |
| Ghost MySQL | Recommended final state: one durable MySQL instance on C3po, following the existing standalone MySQL pattern. First verify MGR health/GTIDs and make the up-to-date C3po member primary while the original group is healthy. During a write freeze, back it up and perform a tested transition/restore to standalone mode. Remove persisted group-replication autostart/settings, retire A/C, and update ProxySQL, services, backups, and monitoring. Do not leave a two-member group or call co-located replicas HA. Verify Ghost publishing and image access. |
| MediaWiki MySQL | Move from Kenobi hostPath to a C3po `zfs-localpv-16k` PVC using a consistent database export/restore or supported backup tool. Preserve grants/users and service identity; verify login, edits, uploads, jobs, and a fresh backup. |
| Conduit / Matrix | Stop the server before copying its RocksDB volume to a newly provisioned C3po PVC. Preserve server identity/config/secrets, ownership, media, and database contents. Validate existing accounts/rooms, media, and federation before reopening normal traffic. |
| VictoriaMetrics | Preserve the TSDB history with its supported snapshot/restore procedure or a stopped-volume copy. Restore to a new C3po PVC and verify historical queries plus incoming samples. Check live Grafana/Alertmanager persistence as well. |
| Job-ops and other PVCs | Include both declared Job-ops PVCs and any live-only PVCs. Stop writers, copy to provisioned C3po volumes, verify ownership/content, and test the owning application. |
| HostPaths and legacy data | Classify every discovered path: migrate authoritative data to C3po; preserve an archive for retired data; rebuild disposable Redis/search/file caches from authoritative sources. Ensure any cache moved to another host is compatible with the target architecture. Record the decision per path. |

For filesystem copies, preserve numeric ownership, modes, ACLs, xattrs, and
symlinks. Use an application-stopped copy or a consistent snapshot; never copy a
live database directory and assume it is recoverable. Prefer fresh destination
PVCs plus restore to hand-editing CSI topology/volume handles. Dataset transfer
with `zfs send/receive` is useful only with an explicit CSI rebinding plan; do not
receive over C3po's root or existing application datasets.

Move stateless Chopper-pinned services too: Cal.diy, Attic placement, and any
live-only workload. Prefer remaining compute nodes for stateless pods and reserve
C3po's resources for data engines. Adjust affinity, taints/tolerations, policies,
backup targets, service selectors, and dashboards together with each migration.
Retain stable client DNS names where possible.

**Exit:** all durable application data is on C3po, no active volume needs Chopper,
application write/read tests pass, and new off-host backups restore successfully.
Consolidation deliberately makes C3po a single storage failure domain.

## P3 — Remove Chopper from the cluster and server network

1. Review remaining pods and disruption budgets, then drain Chopper. Investigate
   blockers rather than forcing away local data or blindly deleting `emptyDir`
   workloads. Verify no remaining application or CSI attachment uses the node.
1. Remove Chopper's k3s module/profile imports, storage-node roles, OpenEBS dataset
   creation unit, cluster-only secrets, CNI forwarding/trust rules, and pod-route
   service. Keep ZFS support for its existing root/home filesystem.
1. Keep Tailscale as a workstation client. Explicitly withdraw the old pod-subnet
   and exit-node advertisements in live Tailscale preferences/admin routing;
   deleting flags from Nix alone may not reset existing preferences. Move an
   actively used exit-node duty to C3po before switching its clients.
1. Remove routes to Chopper's old pod CIDR from C3po, Kenobi, R2D2, and Yoda after
   verifying live CIDR allocation. Repair R2D2's obsolete `serverAddr` to the
   actual control plane. Keep a direct Kenobi API/SSH recovery path in case the
   in-cluster Tailscale API proxy is unavailable.
1. Disable k3s on Chopper, remove the Kubernetes Node after evacuation, and check
   for leftover CNI interfaces/routes/firewall rules. Reboot and verify cleanup.
   Keep source datasets/snapshots until the rollback retention period ends.
1. Inventory live tunnel/listener dependencies; the repository disables host
   cloudflared/Nextcloud, so do not assume there are active duties to migrate.
   Any active required duty must work from C3po or existing ingress before exit.

**Exit:** power Chopper off and verify the cluster, websites, uploads, databases,
backups, and administration from another device still work.

## P4 — Make Chopper the daily driver and admin workstation

- Reuse `profiles/wayland.nix` (Sway/greetd/keyring/polkit) and add a focused
  host display/input configuration. Supply a usable Sway configuration with
  terminal/launcher shortcuts, output scaling, keyboard/touchpad settings,
  notifications, clipboard, screenshots, locking, and idle/suspend handling.
- Add PipeWire/WirePlumber audio, graphical networking, fonts, browser, terminal,
  editor, and the Wayland portals required for screen sharing. Verify actual GPU,
  displays/dock, Wi-Fi, Bluetooth, audio/mic, webcam, and video acceleration.
- Replace `profiles/server-laptop-power.nix` with workstation power policy;
  explicitly set lid/suspend behavior because `profiles/laptop.nix` also ignores
  the lid by default. Test resume before relying on it. Configure a real local
  login password securely and verify lock/unlock; SSH authorized keys do not
  provide a greetd login. Revisit blanket passwordless sudo for interactive use.
- Add `home/chopper-home.nix` and standalone `homeConfigurations."vysakh@chopper"`
  using the existing `mkHome` pattern, `self` injection, and nixvim module. Reuse
  `home/common` and explicitly import `home/common/packages/dev-k8s.nix` (currently
  imported through the Darwin profile). Resolve package/platform differences
  before removing the Mac profile.
- Install the existing administration/development stack: jj, just, nh, treefmt,
  SOPS/age, deploy-rs, kubectl, wrapped Helm/helmfile plugins, cloud CLIs, and the
  user's editor/agent tools. Migrate authentication privately and reauthenticate
  credentials bound to macOS Keychain; retain an offline SOPS recovery key.
- Transfer the repository including unpushed jj revisions and working changes,
  verify the history/content on Chopper, and use `/home/vysakh/nix-config` to
  match its existing `programs.nh.flake`. Verify SSH trust/deployment access to
  every host and GitHub before retiring Mac credentials.
- Fetch a fresh kubeconfig from Kenobi, using the stable API endpoint. Establish
  SOPS access for the operator separately from host runtime decryption; inspect
  actual encrypted recipients and update affected files if recipient rules move.
- Use `nh os switch` for Chopper and `nh home switch` for its standalone home
  profile. Keep `just deploy <host>` for remote servers. Yoda's configured
  Chopper build host becomes an on-demand workstation builder; server runtime
  must not depend on it. Keep native ARM builds on appropriate remote builders.
- Set up personal-data backup and a recovery admin path from a second device.
  Test a file restore, a fleet deploy, cluster administration, and secret editing
  entirely from Chopper. Keep resource-heavy builds bounded for daily usability.

**Exit:** normal work, hardware, suspend/resume, development, administration,
backup, and restore all work with the Mac powered off.

## P5 — Soak, retire Darwin, and clean the repository

Run for at least one full backup cycle and several normal working days (target
one week). Include a C3po reboot/recovery test, a Chopper suspend/reboot, and a
fresh off-host restore. Keep the Mac recoverable until these pass.

Then remove Darwin host/home outputs, `darwinPackages`, Darwin-only inputs and
packages/modules, unused library helpers, and the Darwin supported-system/CI
mapping if nothing still consumes them. Retain portable app configuration that
the Chopper home profile needs. Revoke Mac-only SSH/auth/device access only after
the replacement access and recovery path are proven; erase the Mac last.

Repository change map:

| Area | Files to update/review |
| --- | --- |
| Chopper workstation | `hosts/chopper/{configuration,default,metadata,sops}.nix`, `hosts/chopper/parts/{services,network,power,programs,users,k3s}.nix`, new display/home configuration, `profiles/wayland.nix` only where shared behavior is needed |
| Storage destination | `hosts/c3po/{configuration,sops}.nix`, existing storage profiles; existing disk layout only if a separate capacity upgrade is required |
| Applications | `k8s/clusters/glug-infra/{rustfs,mysql-ghost,mysql-mediawiki,conduit,job-ops,caldiy,attic,mediawiki}`, `k8s/apps/{postgres,victoria-metrics-k8s-stack}`, corresponding backups, monitoring and NetworkPolicies |
| Networking | Remaining hosts' `parts/network.nix`, R2D2 `parts/k3s.nix`, `tailscale/`, API endpoint manifests and live route approvals |
| OpenClaw retirement | `flake.nix`, `flake.lock`, `overlays/default.nix`, Chopper service/secrets files, `docs/openclaw.md`, experiment-specific skill/docs references |
| Darwin retirement | `hosts/darwin/`, `home/darwin*`, `packages/darwin/`, `users/mathewalex.nix` if unused, `flake.nix`, `flake.lock`, `lib/default.nix` |
| Operator workflow | Root and `k8s/Justfile`, `.sops.yaml`, encrypted secrets, `home/common/`, `.envrc` files, agent instructions, `README.md`, `CLAUDE.md`, bootstrap/deploy/security docs and CI configuration |

Fix workflow hazards encountered in this migration: Mac-only task defaults,
hard-coded host lists that omit Yoda, stale HA claims, `regen-certs` targeting
Chopper, and platform-specific paths. Verify existing kubeconfig recipes on
Linux. Check actual command exit status: `k8s::diff` currently masks kubectl
errors, and `k8s::status` can exit early when its unhealthy-pod grep finds none.
Their success banners alone are not acceptance evidence.

Before each implementation revision: format changed files with treefmt, run
appropriate lint/evaluation checks, evaluate every discovered host and the new
home profile, and build the affected configurations. Render affected Kubernetes
resources and inspect diffs without logging decrypted secrets. Deploy one server
at a time using the existing deployment runbook and verify health afterward.
The documentation-only planning revision does not require system builds.

## Rollback and completion rules

- Before destination writes begin: return clients to the fenced source only
  after stopping the destination. Keep the old manifests and source data intact.
- After destination writes begin: do not switch back to a stale source. Freeze
  writers again, transfer new data back or recover forward from a fresh backup,
  validate, and then choose a single writable instance.
- Keep source recovery copies for at least the soak period and until a fresh
  destination backup has passed restore testing. Release old PVCs/datasets only
  after their owners and recovery copies are accounted for.
- Completion means Chopper and the Mac can both be off without breaking hosted
  services; Chopper works as the primary desktop when on; C3po owns application
  persistence; Kenobi's control plane remains healthy; OpenClaw is gone; and
  recovery does not require the retired Mac or a running Chopper.

Downtime and transfer duration are determined after P0's size/throughput and
restore measurements. C3po's single-disk capacity/health and tested recovery are
the main blockers, not the desktop installation.
