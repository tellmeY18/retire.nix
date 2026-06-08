# k8s — Kubernetes resources for the glug-infra cluster

This directory contains all Kubernetes manifests and Helm values for the
`glug-infra` k3s cluster. It is **not** managed by a GitOps controller;
resources are applied manually via `just k8s::apply` from the laptop.

> See [`docs/k3s-cnpg.md`](../docs/k3s-cnpg.md) for the full architecture,
> including the HA reality-check (the 2-node etcd quorum trap), Tailscale
> ACL requirements, and secret-management model.

---

## Naming policy (cluster vs. node)

The directory names and resource names here are deliberately **cluster-scoped**,
not host-scoped:

| Concept | Name | Note |
|---|---|---|
| The k3s cluster | `glug-infra` | Lives in `k8s/clusters/glug-infra/` |
| The Postgres deployment | `postgres` (Helm release) | Lives in `k8s/apps/postgres/` |
| The first / current node | `chopper` | Configured under `hosts/chopper/` |

When a second node joins (`hosts/<new>/`), nothing under `k8s/` changes — the
new node simply pulls in `profiles/k3s-node.nix` and contributes more capacity
to the existing cluster. The CNPG `Cluster` is reconciled across whatever
nodes are present; the Tailscale `pg-rw` MagicDNS endpoint stays stable.

---

## Architecture split: Nix vs helmfile vs kustomize

| Layer | Managed by | What lives there |
|---|---|---|
| **NixOS bootstrap** | `nh os switch` | k3s itself; OpenEBS ZFS LocalPV CSI driver; the `zfs-localpv` and `zfs-localpv-16k` StorageClasses; Tailscale Kubernetes operator. Declared via `services.k3s.charts` in `modules/services/k3s.nix` and present on every node the moment k3s starts — no human intervention required after a reboot. |
| **CNPG operator** | `helmfile` | The `cloudnative-pg` chart in the `cnpg-system` namespace. Provides CRDs + the controller. |
| **Postgres workloads** | `helmfile` (cnpg/cluster chart) | One Helm release per Postgres cluster. Renders the `Cluster`, `ScheduledBackup`, and `Pooler` CRs from values files in `apps/postgres/`. |
| **MySQL workloads** | `kustomize` + `sops` | Two independent deployments, no operator. `mysql-ghost` — a 3-member MySQL Group Replication (MGR) cluster (StatefulSets + `proxysql-ghost`) for the `ghost`/`activitypub` DBs. `mysql-mediawiki` — a standalone single-node Percona Server for MediaWiki. Manifests under `clusters/glug-infra/mysql-ghost/` and `clusters/glug-infra/mysql-mediawiki/`; ProxySQL/backup secrets are sops-encrypted. |
| **RustFS object storage** | `kustomize` + `sops` | Standalone, operator-free. A single RustFS `StatefulSet` (one pod, one ZFS-backed PVC, no erasure coding) + its Services under `clusters/glug-infra/rustfs/`. The `rustfs-credentials` Secret is sops-decrypted and applied before the StatefulSet. |
| **Monitoring stack** | `helmfile` | `victoria-metrics-k8s-stack` chart (v0.77.0) in the `monitoring` namespace. Provides VMSingle + VMAgent + VMAlert + VMAlertmanager + Grafana + VictoriaMetrics Operator + CRDs (VMRule, VMPodScrape, VMServiceScrape). |
| **Cluster glue** | `kubectl apply -k` (kustomize) | Namespaces (with PSA labels), NetworkPolicies, and Tailscale LoadBalancer Services (pg-rw, grafana). |
| **Encrypted secrets** | `helm-secrets` (sops) | S3 backup credentials live in `apps/postgres/secrets.yaml` and the Grafana admin password in `apps/victoria-metrics-k8s-stack/secrets.yaml` — both sops-encrypted Helm values, merged by `helm-secrets` at install time. No raw `Secret` manifest ever touches git or the kustomize pipeline. |

---

## Namespace layout

| Namespace | Created by | Contents |
|---|---|---|
| `cnpg-system` | helmfile chart `createNamespace: true` | CNPG operator Deployment + webhooks |
| `cnpg-clusters` | `namespace.yaml` (kustomize) | Postgres `Cluster`, `Pooler`, `ScheduledBackup`, `Service`, `NetworkPolicy`, `Secret` (rendered by chart) |
| `mysql-ghost` | `mysql-ghost/namespace.yaml` (kustomize) | MGR member StatefulSets (`mysql-ghost-a/b/c`), `proxysql-ghost` Deployment, hourly backup `CronJob`, `NetworkPolicy`, sops `Secret`s |
| `mysql-mediawiki` | `mysql-mediawiki/namespace.yaml` (kustomize) | Standalone Percona Server StatefulSet (single node, kenobi hostPath), hourly backup `CronJob`, `NetworkPolicy`, sops `Secret`s |
| `rustfs-clusters` | `rustfs/namespace.yaml` (kustomize) | Standalone RustFS `StatefulSet` (single pod), its PVC, credentials `Secret`, `NetworkPolicy`, Tailscale `Service` |
| `changala` | `changala/namespace.yaml` (kustomize) | Changala Ring server `Deployment`, `ConfigMap` (atrg.toml), credentials `Secret` (sops), `NetworkPolicy`, Tailscale `Service` |
| `monitoring` | `monitoring/namespace.yaml` (kustomize) | VMSingle, VMAgent, VMAlert, VMAlertmanager, Grafana, node-exporter, kube-state-metrics, Grafana Tailscale Service |

The `cnpg-clusters` namespace carries `pod-security.kubernetes.io/enforce=restricted`
labels so any pod scheduled there must comply with the PodSecurity restricted
profile. CNPG's pods (operator, instances, PgBouncer) all comply by default.

The `rustfs-clusters` namespace uses `pod-security.kubernetes.io/enforce=baseline`
because the RustFS operator (v0.1.0) does not yet set a restricted-compatible
securityContext on its StatefulSet pods. Audit/warn remain `restricted` so
we're alerted when upstream fixes this.

The `monitoring` namespace uses `pod-security.kubernetes.io/enforce=privileged`
because node-exporter requires `hostNetwork`/`hostPID`/`hostPath` access for
complete host-level metrics collection.

---

## First-time apply

### Prerequisites

- `helmfile` + `helm` + `helm-secrets` + `helm-git` plugins installed
  (all Nix-managed via `wrapHelm` in `home/common/packages/dev-k8s.nix`;
  no manual `helm plugin install` needed).
- `kubectl` configured against the cluster. On any k3s node this is automatic
  via `KUBECONFIG=/etc/rancher/k3s/k3s.yaml` exported by `profiles/k3s-node.nix`.
- `sops` on `$PATH`; your age private key loaded (see [`docs/secrets.md`](../docs/secrets.md)).
- An off-site S3-compatible bucket already created (Backblaze B2, Cloudflare R2, AWS S3, …).
- The `kubectl-cnpg` plugin: `kubectl krew install cnpg`.

### Steps

```sh
# 1. Edit the bucket name + endpoint URL in the (plaintext) values file:
$EDITOR k8s/apps/postgres/values.yaml
#   backups.s3.bucket: "glug-infra-pg-backups"
#   backups.endpointURL: "https://<account>.r2.cloudflarestorage.com"   # if R2

# 2. Fill in real S3 credentials, then encrypt the secret values file:
$EDITOR k8s/apps/postgres/secrets.yaml
#   backups.s3.accessKey: "<real key id>"
#   backups.s3.secretKey: "<real secret>"
sops --encrypt --in-place k8s/apps/postgres/secrets.yaml
head -3 k8s/apps/postgres/secrets.yaml         # should now start with `sops:`

# 3. Encrypt the (currently empty) operator values file too:
sops --encrypt --in-place k8s/apps/cnpg-operator/secrets.yaml

# 4. Apply.
just k8s::apply
```

`just k8s::apply` runs:

1. `kubectl apply -k` — creates Namespaces (with PSA labels), NetworkPolicies,
   and Tailscale LoadBalancer Services for CNPG and RustFS, plus the
   `mysql-ghost` / `mysql-mediawiki` workloads.
2. `helmfile sync` — installs/upgrades all operators (VM stack, CNPG,
   RustFS) and the Postgres workloads. helm-secrets decrypts each
   `secrets.yaml` inline and merges it on top of the corresponding `values.yaml`.
3. RustFS credentials Secret — sops-decrypted and applied (must exist before
   the Tenant CR so the operator can validate immediately).
4. RustFS Tenant CR — applied now that the CRD + credentials both exist.
5. `kubectl apply -k monitoring` — applies VMRules, VMServiceScrapes, and
   Grafana dashboards (requires VM operator CRDs from step 2).

### Preview before applying

```sh
just k8s::diff
```

This runs `helmfile diff` then `kubectl diff -k …`. The kubectl diff exit
code is squashed because absent objects return non-zero on a clean cluster.

---

## Day-2 helpers

### CNPG

```sh
just k8s::cnpg-status              # kubectl cnpg status postgres
just k8s::cnpg-operator-logs       # tail operator logs
just k8s::cnpg-primary-logs        # tail current primary
just k8s::cnpg-backup-now          # on-demand base backup
just k8s::cnpg-backup-list         # list Backup objects with phase
```

### MySQL — `mysql-ghost` (MGR)

```sh
# MGR membership / current primary
kubectl exec -n mysql-ghost mysql-ghost-a-0 -c mysql -- \
  mysql -uroot -p"$ROOT" -e \
  "SELECT member_host,member_state,member_role FROM performance_schema.replication_group_members;"

# ProxySQL routing view (admin on :6032)
kubectl exec -n mysql-ghost deploy/proxysql-ghost -- \
  mysql -uradmin -p... -h127.0.0.1 -P6032 -e \
  "SELECT hostgroup_id,hostname,status FROM runtime_mysql_servers;"
```

Bootstrap, failover, and restore procedures live in
[`../docs/mysql-ghost-mgr.md`](../docs/mysql-ghost-mgr.md).

### RustFS (S3-compatible object storage)

Standalone, operator-free: a single StatefulSet pod (`rustfs-0`), one
ZFS-backed PVC, no erasure coding. Stable endpoint:
`rustfs-storage-io.rustfs-clusters.svc:9000`.

```sh
just k8s::rustfs-status            # StatefulSet + pod status
just k8s::rustfs-describe          # describe the pod (events/probes)
just k8s::rustfs-pod-logs          # tail the pod logs
just k8s::rustfs-pods              # list the RustFS pod
just k8s::rustfs-pvcs              # show the PVC + capacity
just k8s::rustfs-port-forward      # port-forward S3 API to localhost:9000
just k8s::rustfs-health            # pod ready + service endpoint
just k8s::rustfs-apply-secret      # apply sops-decrypted credentials
just k8s::rustfs-capacity          # query RustFS capacity metrics
just k8s::rustfs-node-status       # query RustFS drive status metrics
just k8s::rustfs-error-rate        # query RustFS S3 error rate
```

### Monitoring

```sh
just k8s::grafana-open             # open Grafana in browser via tailnet
just k8s::grafana-port-forward     # fallback: port-forward Grafana to localhost:3000
just k8s::vm-port-forward          # port-forward VMSingle UI to localhost:8428
just k8s::vmagent-targets          # show VMAgent active scrape target count
just k8s::vm-operator-logs         # tail VictoriaMetrics operator logs
just k8s::vmagent-logs             # tail VMAgent logs
just k8s::vmalert-logs             # tail VMAlert logs
just k8s::alerts                   # show all firing alerts
just k8s::cnpg-replication-lag     # query CNPG replication lag from VMSingle
```

For switchover, drain, and restore procedures see [`docs/runbooks/`](docs/runbooks/).

---

## Editing secrets

Secrets live as sops-encrypted Helm values files:

- `k8s/apps/postgres/secrets.yaml` — S3 backup credentials
- `k8s/apps/cnpg-operator/secrets.yaml` — operator-side image-pull
  credentials (empty by default)
- `k8s/apps/victoria-metrics-k8s-stack/secrets.yaml` — Grafana admin password
- `k8s/clusters/glug-infra/mysql-ghost/*.enc.yaml` — root/app/GR/backup
  passwords and the `proxysql-ghost` config for the MGR cluster
- `k8s/clusters/glug-infra/mysql-mediawiki/*.enc.yaml` — root/app and S3
  backup credentials for the standalone MediaWiki MySQL
- `k8s/clusters/glug-infra/rustfs/credentials-secret.enc.yaml` — RustFS
  admin access/secret keys (applied via `just k8s::rustfs-apply-secret`)

To edit either:

```sh
just k8s::edit-secret k8s/apps/postgres/secrets.yaml
```

This opens the file in `$EDITOR` via `sops`, which encrypts on save. The
`.sops.yaml` at the repo root defines which age keys are recipients for each
path pattern; both files are covered by the existing `k8s/.../secrets.yaml`
rule (master-key only — no host needs to decrypt these).

---

## Monitoring

The cluster runs `victoria-metrics-k8s-stack` v0.77.0 (VMSingle + VMAgent +
VMAlert + VMAlertmanager + Grafana) in the `monitoring` namespace. Key
integration points:

- **CNPG instance metrics** — VMPodScrape on port 9187 (defined in
  `clusters/glug-infra/monitoring/cnpg-cluster-vmpodscrape.yaml`)
- **CNPG VMRules** — alerts for replication lag, backup failures, WAL
  archiving, and primary availability
- **PgBouncer metrics** — VMPodScrape on port 9127 (pooler monitoring)
- **CNPG operator metrics** — VMPodScrape on the operator's `/metrics`
  endpoint (defined in `cnpg-operator-vmpodscrape.yaml`)
- **mysql-ghost instance metrics** — VMServiceScrape on the mysqld_exporter
  sidecar (port 9104) of each MGR member in the `mysql-ghost` namespace
- **proxysql-ghost metrics** — VMServiceScrape on the ProxySQL stats port in
  the `mysql-ghost` namespace
- **mysql-ghost VMRules** — alerts for MGR health (members ONLINE, primary
  present, replication lag via `performance_schema.replication_group_members`)
- **RustFS metrics** — VMServiceScrape on port 9000, scraping MinIO v2
  metrics API (`/minio/v2/metrics/cluster` + `/minio/v2/metrics/node`)
- **RustFS VMRules** — alerts for cluster health (nodes/drives offline,
  capacity), S3 errors, and healing progress
- **RustFS Grafana dashboard** — cluster status, capacity, S3 traffic,
  per-node metrics
- **Grafana dashboards** — auto-imported from ConfigMaps labelled
  `grafana_dashboard: "1"` across all namespaces (sidecar)

Grafana is reachable at `http://grafana.<tailnet>.ts.net:3000` via the
Tailscale LoadBalancer Service in `clusters/glug-infra/monitoring/`.

---

## Stable Postgres endpoint

Webservices connect to:

```
pg-rw.<tailnet>.ts.net:5432
```

For MySQL, there is no tailnet endpoint — the consumers are in-cluster apps.
Ghost/ActivityPub connect to the MGR cluster via its in-cluster ProxySQL:

```
proxysql-ghost.mysql-ghost.svc:3306
```

MediaWiki connects directly to its standalone MySQL in `mysql-mediawiki`.

### PostgreSQL traffic path

The PostgreSQL tailnet hostname is owned by the Tailscale operator and stays registered
as long as the cluster is running. Traffic flows:

```
webservice
  → pg-rw.<tailnet>.ts.net:5432   (Tailscale MagicDNS)
  → ts-proxy pod                   (LoadBalancer Service in cnpg-clusters)
  → postgres-pooler-rw Service     (created by CNPG Pooler CR)
  → PgBouncer pods (transaction mode)
  → postgres-rw Service            (always points at current primary)
  → PostgreSQL primary pod
```

When CNPG promotes a new primary the `postgres-rw` Service endpoints update
within seconds; PgBouncer reconnects on its own. Webservices see at most a
brief connection-pool churn.

The Tailscale Service has `sessionAffinity: ClientIP` so a single webservice
stays pinned to one PgBouncer pod for the lifetime of its connection pool —
purely a latency optimisation; PgBouncer is stateless across pods, so a sudden
re-pinning is harmless.

### MySQL traffic path (`mysql-ghost` MGR)

```
Ghost / ActivityPub pod
  → proxysql-ghost.mysql-ghost.svc:3306   (in-cluster Service)
  → proxysql-ghost pod (MGR-aware routing, kenobi)
  → writer hostgroup HG10                 (current MGR primary)
  → mysql-ghost primary pod (a on chopper, or failover target)
```

ProxySQL's MGR monitor reads `sys.gr_member_routing_candidate_status` to track
the current primary. When MGR elects a new primary (after a pod or node loss),
ProxySQL re-points HG10 within seconds. Webservices see at most a brief
connection drop. MediaWiki is not in this path — it talks to its standalone
`mysql-mediawiki` MySQL directly.

### RustFS S3 traffic path

```
client / webservice
  → s3.<tailnet>.ts.net:9000          (Tailscale MagicDNS)
  → ts-proxy pod                       (LoadBalancer Service in rustfs-clusters)
  → rustfs-storage-io Service          (ClusterIP, port 9000)
  → rustfs-0 pod                       (standalone StatefulSet, single drive)
```

RustFS runs standalone: ONE pod with a SINGLE ZFS-backed volume, no erasure
coding and no operator. In-cluster apps hit `rustfs-storage-io:9000` directly.
This is deliberately not internally redundant — on one laptop NVMe, erasure
coding across local "drives" is not real redundancy and only adds write
amplification plus a quorum gate that crashlooped under node flapping.
Durability lives in ZFS (checksums, COW, snapshots) plus off-site backup (TBD).

---

## Runbooks

| Scenario | Runbook |
|---|---|
| Manual switchover / primary node dies | [`docs/runbooks/failover.md`](docs/runbooks/failover.md) |
| Point-in-time recovery from S3 backup | [`docs/runbooks/restore-pitr.md`](docs/runbooks/restore-pitr.md) |
| Adding a second k3s server node | [`docs/runbooks/add-node.md`](docs/runbooks/add-node.md) |

---

## Directory layout

```
k8s/
├── README.md                                # this file
├── helmfile.yaml                            # victoria-metrics-k8s-stack + cnpg + rustfs charts
├── apps/
│   ├── cnpg-operator/
│   │   ├── values.yaml                      # plain Helm values
│   │   └── secrets.yaml                     # sops-encrypted Helm values
│   ├── victoria-metrics-k8s-stack/
│   │   ├── values.yaml                      # VMSingle + VMAgent + Grafana + Alertmanager config
│   │   └── secrets.yaml                     # sops-encrypted Grafana admin password
│   ├── postgres/
│   │   ├── values.yaml                      # Cluster + Pooler + Backup config
│   │   └── secrets.yaml                     # sops-encrypted S3 credentials
│   └── rustfs/
│       └── values.yaml                      # standalone RustFS notes (no operator)
├── clusters/
│   └── glug-infra/
│       ├── kustomization.yaml               # entry point (cnpg-clusters namespace)
│       ├── namespace.yaml                   # cnpg-clusters + PSA labels
│       ├── networkpolicy.yaml               # default-deny + allow rules
│       ├── tailscale-pg-service.yaml        # Tailscale LB: pg-rw
│       ├── mysql-ghost/
│       │   ├── kustomization.yaml           # entry point (mysql-ghost namespace)
│       │   ├── namespace.yaml               # mysql-ghost + PSA labels
│       │   ├── networkpolicy.yaml           # default-deny + MGR + ProxySQL rules
│       │   ├── mysql-ghost-a/b/c.yaml        # 3 MGR member StatefulSets
│       │   ├── proxysql-ghost.yaml           # MGR-aware ProxySQL Deployment + Service
│       │   ├── backup-cronjob.yaml           # hourly logical dump → S3
│       │   └── *.enc.yaml                    # sops-encrypted Secrets (root/app/gr/backup/proxysql)
│       ├── mysql-mediawiki/
│       │   ├── kustomization.yaml           # entry point (mysql-mediawiki namespace)
│       │   ├── namespace.yaml               # mysql-mediawiki + PSA labels
│       │   ├── networkpolicy.yaml           # default-deny + MediaWiki rules
│       │   ├── mysql.yaml                    # standalone Percona Server (kenobi hostPath)
│       │   ├── backup-cronjob.yaml           # hourly logical dump → S3
│       │   └── *.enc.yaml                    # sops-encrypted Secrets
│       ├── rustfs/
│       │   ├── kustomization.yaml           # entry point (rustfs-clusters namespace)
│       │   ├── namespace.yaml               # rustfs-clusters + PSA baseline labels
│       │   ├── networkpolicy.yaml           # default-deny + S3 + inter-node rules
│       │   ├── credentials-secret.enc.yaml  # RustFS admin credentials (sops-encrypted)
│       │   ├── tenant.yaml                  # RustFS Tenant CR (4 servers × 2 vols, applied post-helmfile)
│       │   └── tailscale-s3-service.yaml    # Tailscale LB: s3
│       └── monitoring/
│           ├── kustomization.yaml           # entry point (monitoring namespace)
│           ├── namespace.yaml               # monitoring + PSA labels
│           ├── tailscale-grafana-service.yaml  # Tailscale LB: grafana
│           ├── cnpg-cluster-vmpodscrape.yaml
│           ├── cnpg-pooler-vmpodscrape.yaml
│           ├── cnpg-operator-vmpodscrape.yaml
│           ├── cnpg-vmrules.yaml
│           ├── mysql-ghost-vmservicescrape.yaml
│           ├── mysql-ghost-vmrules.yaml
│           ├── proxysql-ghost-vmservicescrape.yaml
│           ├── rustfs-vmservicescrape.yaml
│           ├── rustfs-vmrules.yaml
│           ├── rustfs-grafana-dashboard.yaml
│           ├── pvc-storage-vmrules.yaml
│           ├── laptop-battery-vmrules.yaml
│           ├── zfs-vmrules.yaml
│           ├── zfs-grafana-dashboard.yaml
│           ├── laptop-battery-grafana-dashboard.yaml
│           └── cluster-overview-grafana-dashboard.yaml
└── docs/
    └── runbooks/
        ├── failover.md
        ├── restore-pitr.md
        └── add-node.md
```

---

## Verifying a healthy install

After the first `just k8s::apply`, walk through these checks:

```sh
# Monitoring stack is up.
kubectl -n monitoring get deploy                      # vmks-* deployments + grafana
kubectl -n monitoring get pods                         # all Running

# CNPG operator is up.
kubectl -n cnpg-system get deploy
kubectl -n cnpg-system get pods                        # 1/1 Running

# CRDs installed.
kubectl get crd | grep cnpg                            # cluster, pooler, backup, scheduledbackup
kubectl get crd | grep rustfs                           # tenants.rustfs.com

# CNPG cluster reaches "Cluster in healthy state".
just k8s::cnpg-status

# All 3 CNPG instances Running, exactly one is primary.
kubectl -n cnpg-clusters get pods -l cnpg.io/cluster=postgres-cluster -o wide

# PgBouncer pods Running.
kubectl -n cnpg-clusters get pods -l cnpg.io/poolerName=postgres-pooler-rw

# RustFS Tenant is Ready with all 4 pods.
just k8s::rustfs-status                                 # STATE = Ready
just k8s::rustfs-pods                                   # 4/4 Running

# RustFS S3 health check.
just k8s::rustfs-health

# mysql-ghost MGR cluster is healthy (3 members ONLINE, one PRIMARY).
kubectl -n mysql-ghost get pods -o wide                 # a→chopper, b→c3po, c→kenobi
kubectl exec -n mysql-ghost mysql-ghost-a-0 -c mysql -- \
  mysql -uroot -p"$ROOT" -e \
  "SELECT member_host,member_state,member_role FROM performance_schema.replication_group_members;"

# Tailscale ts-proxy pods up; devices registered on the tailnet.
kubectl -n tailscale get pods
tailscale status | grep -E 'pg-rw|s3|grafana'

# Trigger an immediate CNPG backup; confirm it completes.
just k8s::cnpg-backup-now
just k8s::cnpg-backup-list

# Connect from a tailnet client.
psql "postgres://app:$(kubectl -n cnpg-clusters get secret postgres-cluster-app -o jsonpath='{.data.password}' | base64 -d)@pg-rw.<tailnet>.ts.net:5432/app"

# Grafana reachable on the tailnet.
curl -s http://grafana.<tailnet>.ts.net:3000/api/health | jq .

# VMAgent is scraping targets.
just k8s::vmagent-targets

# RustFS console reachable.
curl -s http://s3.<tailnet>.ts.net:9001/ -o /dev/null -w '%{http_code}\n'
```

If any step fails, the `## 6. Day-2 operations` section of
[`docs/k3s-cnpg.md`](../docs/k3s-cnpg.md) maps the most common error strings
(operator OAuth failures, helm-install Job errors, etc.) to fixes.
