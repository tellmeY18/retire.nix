# CLAUDE.md — Architecture & Conventions

Context for AI assistants and contributors. `ROADMAP.md` has the milestone plan.

---

## Conventions

- **One module = one concern.** No "kitchen sink" host files.
- **No hard-coded user paths.** Use sops or `config.users.users.<name>.home`.
- **Per-host metadata** in `hosts/<name>/metadata.nix` (hostname, system, roles, etc.).
- **Per-user metadata** in `users/<name>.nix` (name, email, ssh keys).
- **Profiles/roles** in `profiles/<role>.nix`: composed by hosts via `metadata.roles`.
- **Formatting**: `treefmt` is canonical (nixpkgs-fmt + shfmt + mdformat).
- **Secrets**: `sops-nix` with age keys per host. `.sops.yaml` defines creation rules.
- **Deploy**: `nh` for local switches, `deploy-rs` for remote NixOS hosts.

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

## 8. MySQL on k3s — `mysql-ghost` (MGR) + `mysql-mediawiki` (standalone)

The Percona XtraDB Cluster (PXC) operator has been **fully decommissioned**
(operator, the `mysql` workload, HAProxy, its backups, helmfile releases, and
all `pxc-*` manifests/monitoring are gone). MySQL is now served by two
independent deployments on the `glug-infra` cluster:

- **`mysql-ghost`** — a 3-member **MySQL Group Replication (MGR)** cluster
  (single-primary) for the write-sensitive `ghost` (Ghost CMS) and
  `activitypub` (Ghost ActivityPub/fediverse) databases. Genuinely HA.
- **`mysql-mediawiki`** — a **standalone single-node Percona Server 8.0**
  for MediaWiki only. Not HA (single node + hourly S3 backups).

Full architecture + bootstrap runbook lives in `docs/mysql-ghost-mgr.md`;
this section is the summary.

### 8.1 `mysql-ghost` — Group Replication for Ghost + ActivityPub

Three MGR members, single-primary, fronted by a dedicated MGR-aware
**`proxysql-ghost`** that auto-routes writes to the current primary by
reading `sys.gr_member_routing_candidate_status` (writer HG10 / reader HG20).

| Member | Node | Storage | Role |
|---|---|---|---|
| `mysql-ghost-a` | chopper | ZFS (`zfs-localpv-16k`) | preferred PRIMARY (weight 50) |
| `mysql-ghost-b` | c3po | ZFS (`zfs-localpv-16k`) | secondary (weight 40) |
| `mysql-ghost-c` | kenobi | hostPath (`/var/lib/mysql-ghost`) | quorum-only, never primary (weight 10) |

- **HA:** 3 members tolerate one failure (majority = 2/3). This survived a
  real chopper node failure with automatic failover during deployment.
  `mysql-ghost-c` is a full data node (MGR has no lightweight arbiter)
  whose only job is the third vote; it serves no application traffic.
- **Storage:** the two storage members use the `zfs-localpv-16k`
  StorageClass (16k recordsize matches InnoDB's 16KB page) bootstrapped in
  `modules/services/k3s.nix`; the kenobi quorum member uses a hostPath.
- **Backups:** hourly logical dump via a CronJob to `s3://mysql-backups/ghost/`.
- **Consumers:** Ghost pods connect to `proxysql-ghost.mysql-ghost.svc:3306`.

### 8.2 `mysql-mediawiki` — standalone Percona Server for MediaWiki

MediaWiki is deliberately kept **off** the MGR cluster: its schema has 52
primary-key-less tables (MediaWiki core + SemanticMediaWiki `smw_*` + Cargo
`cargo_*`), and Group Replication requires a primary key on every table. So
MediaWiki stays on a plain **standalone single-node Percona Server 8.0** on
**kenobi** (hostPath), serving only MediaWiki. MediaWiki connects directly to
its MySQL — there is no ProxySQL in front. Not HA; protected by hourly S3
backups.

> The old standalone `proxysql` (namespace `proxysql`) that fronted PXC
> (HG10 = PXC writer, HG20 = mysql-ram reader) has also been removed — it is
> vestigial. This is distinct from `proxysql-ghost`, which stays.

### 8.3 ZFS optimisation for InnoDB

The default `zfs-localpv` StorageClass (8k recordsize) is tuned for
PostgreSQL. MySQL/InnoDB uses **16KB pages**, so the `zfs-localpv-16k`
StorageClass (`recordsize=16k`, `compression=zstd`, same `rpool/openebs`
pool) is bootstrapped in `modules/services/k3s.nix` and used by the
`mysql-ghost` storage members. InnoDB tuning applied to every MySQL pod:

- `innodb_doublewrite=0` — ZFS is copy-on-write; the doublewrite buffer
  is redundant and wastes IOPS.
- `innodb_flush_method=O_DIRECT` — bypass the Linux page cache; let ZFS
  ARC handle caching.
- `innodb_flush_neighbors=0` — NVMe doesn't benefit from sequential
  neighbour flushing.
- `innodb_io_capacity=2000` / `innodb_io_capacity_max=4000` — NVMe can
  handle more IOPS than spinning rust defaults.

### 8.4 Stable MySQL URL — how `mysql-ghost` survives node loss

1. Ghost connects to `proxysql-ghost.mysql-ghost.svc:3306`.
2. ProxySQL's MGR monitor tracks the current primary via
   `sys.gr_member_routing_candidate_status` and keeps it in writer HG10.
3. If the primary pod / its node dies:
   - MGR elects a new primary from the surviving members (weights bias
     election to `a` then `b`; `c` is never primary unless last survivor).
   - ProxySQL re-points HG10 at the new primary within seconds.
4. Caveat: if storage drops below majority (e.g. both storage nodes gone),
   the group goes read-only until quorum returns. `mysql-mediawiki` is a
   single node, so it is simply down while kenobi is down.

### 8.5 Day-2 operations

See `docs/mysql-ghost-mgr.md` for the bootstrap, ProxySQL routing-view
setup, failover, and restore runbooks. Quick status:

```sh
# MGR membership / current primary
kubectl exec -n mysql-ghost mysql-ghost-a-0 -c mysql -- \
  mysql -uroot -p"$ROOT" -e \
  "SELECT member_host, member_state, member_role \
   FROM performance_schema.replication_group_members;"

# ProxySQL routing (admin on :6032)
kubectl exec -n mysql-ghost deploy/proxysql-ghost -- \
  mysql -uradmin -p... -h127.0.0.1 -P6032 -e \
  "SELECT hostgroup_id,hostname,status FROM runtime_mysql_servers;"
```

---

## 9. Monitoring Architecture — Reusability & Laptop Battery

This section documents how monitoring is structured for **zero-effort
scale-out** (adding nodes requires no monitoring config changes) and
**laptop-specific concerns** (battery level, AC power loss).

### 9.1 Reusability guarantees (what happens when you add a node)

Every monitoring component is designed so that adding a new k3s node
(whether it's a second laptop, a Pi, or a VPS) requires **zero changes**
to monitoring configuration:

| Component | Why it auto-discovers new nodes |
|---|---|
| **node-exporter** | DaemonSet — k8s schedules one pod per node automatically. |
| **ZFS PrometheusRules** | PromQL uses generic `node_zfs_*` metrics with `$labels.instance` — no hostnames. |
| **ZFS Grafana dashboard** | Template variable `$instance` from `label_values()` — new nodes appear in the dropdown. |
| **Battery PrometheusRules** | PromQL uses `node_power_supply_*` metrics with `$labels.instance` — no hostnames. On non-laptop nodes the metrics simply don't exist (harmless no-op). |
| **Battery Grafana dashboard** | Template variable `$instance` from `label_values(node_power_supply_online, instance)` — only battery-equipped nodes appear. |
| **PVC storage alerts** | Cluster-wide — `kubelet_volume_stats_*` has no namespace filter. ANY PVC in ANY namespace is monitored. |
| **CNPG PrometheusRules** | PromQL uses generic `cnpg_*` metrics — fires on any CNPG pod regardless of node. |
| **MGR PrometheusRules** | PromQL uses generic mysqld_exporter metrics + `performance_schema.replication_group_members` scrapes — fires on any `mysql-ghost` member regardless of node. |
| **Prometheus itself** | `*SelectorNilUsesHelmValues: false` + `*NamespaceSelector: {}` — discovers monitors in ALL namespaces. |

**What IS per-deployment (not per-node):** PodMonitors and ServiceMonitors
reference specific Helm release names / CR names (`postgres-cluster`,
`mysql`). These are per-deployment, not per-node — they don't need
changing when nodes are added. They only need updating if you deploy a
*second instance* of CNPG or MySQL with a different name.

### 9.2 Laptop battery monitoring

The k3s nodes are old laptops. Running on battery is abnormal (they're
servers), so battery monitoring is treated as **infrastructure alerting**,
not just nice-to-have dashboards.

**How it works:**

1. **node-exporter** (DaemonSet, hostNetwork, hostPID) reads
   `/sys/class/power_supply/` via host filesystem mounts. The
   `powersupply` collector is enabled by default. Note: metrics use
   `power_supply="AC0"` / `power_supply="BAT0"` labels (not
   `type="Mains"` / `type="Battery"` — the `type` label only appears
   on `node_power_supply_info`).
2. **PrometheusRules** (`laptop-battery-prometheusrules.yaml`) fire
   alerts based on these metrics.
3. **Grafana dashboard** (`laptop-battery-grafana-dashboard.yaml`)
   provides visual status.
4. **Justfile recipes** (`just k8s::battery-*`) for quick CLI checks.

**Alert escalation ladder:**

| Alert | Severity | Fires when | `for` |
|---|---|---|---|
| `NodeOnBattery` | warning | AC power lost | 2m |
| `NodeBatteryLow` | warning | < 30% AND on battery | 5m |
| `NodeBatteryCritical` | critical | < 15% AND on battery | 2m |
| `NodeBatteryEmergency` | critical | < 5% AND on battery | immediate |
| `NodeBatteryHealthDegraded` | warning | Full capacity < 50% of design | 1h |

Key design decisions:
- Battery level alerts use `and on (instance)` to join with AC status —
  a plugged-in laptop with a depleted battery does NOT trigger level alerts
  (only the health alert, if applicable).
- Battery % is computed from `energy_watthour / energy_full`
  (coulomb-counter based) rather than the raw sysfs `capacity` attribute
  (firmware estimate, often inaccurate).
- On non-laptop nodes, all `node_power_supply_*` metrics are absent, so
  every rule evaluates to empty — zero noise.

**Day-2 operations:**

```sh
just k8s::battery-ac-status   # AC power status per node (1=AC, 0=battery)
just k8s::battery-level       # battery charge % per node
just k8s::battery-health      # battery health % per node (full vs design)
just k8s::battery-energy      # remaining Wh per node
```

### 9.3 PVC storage monitoring (cluster-wide)

PVC storage alerts were refactored from per-namespace rules (hardcoded
`namespace="cnpg-clusters"` / `namespace="mysql-ghost"`) into a single
`pvc-storage-prometheusrules.yaml` that monitors **all PVCs in all
namespaces** without any namespace filter.

This means:
- Adding a new service with PVCs → automatically monitored.
- Adding a new namespace → automatically monitored.
- No copy-paste of alert groups required.

The inode alert includes a `kubelet_volume_stats_inodes > 0` guard
because ZFS volumes may not report inode statistics.

### 9.4 Files summary

| File | Purpose | Node-agnostic? |
|---|---|---|
| `monitoring/laptop-battery-prometheusrules.yaml` | Battery level + AC power alerts | ✅ |
| `monitoring/laptop-battery-grafana-dashboard.yaml` | Battery status dashboard | ✅ |
| `monitoring/pvc-storage-prometheusrules.yaml` | Cluster-wide PVC capacity alerts | ✅ |
| `monitoring/zfs-prometheusrules.yaml` | ZFS pool health + ARC alerts | ✅ |
| `monitoring/zfs-grafana-dashboard.yaml` | ZFS metrics dashboard | ✅ |
| `monitoring/cnpg-prometheusrules.yaml` | CNPG replication/health alerts | ✅ |
| `monitoring/mysql-ghost-prometheusrules.yaml` | MGR replication/health alerts | ✅ |
| `monitoring/cnpg-cluster-podmonitor.yaml` | Scrapes CNPG pods | per-deployment |
| `monitoring/cnpg-pooler-podmonitor.yaml` | Scrapes PgBouncer pods | per-deployment |
| `monitoring/mysql-ghost-servicemonitor.yaml` | Scrapes mysqld_exporter on MGR members | per-deployment |
| `monitoring/proxysql-ghost-servicemonitor.yaml` | Scrapes ProxySQL stats | per-deployment |
