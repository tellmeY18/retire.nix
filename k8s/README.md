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
| **PXC operator** | `helmfile` | The `pxc-operator` chart in the `pxc-system` namespace. Provides CRDs + the controller. |
| **MySQL workloads** | `helmfile` (percona/pxc-db chart) | One Helm release per PXC cluster. Renders the `PerconaXtraDBCluster` CR (PXC nodes + HAProxy + backups) from values files in `apps/mysql/`. |
| **Monitoring stack** | `helmfile` | `victoria-metrics-k8s-stack` chart in the `monitoring` namespace. Provides VMSingle + VMAgent + VMAlert + VMAlertmanager + Grafana + VictoriaMetrics Operator + CRDs (VMRule, VMPodScrape, VMServiceScrape). |
| **Cluster glue** | `kubectl apply -k` (kustomize) | Namespaces (with PSA labels), NetworkPolicies, and Tailscale LoadBalancer Services (pg-rw, mysql-rw, grafana). |
| **Encrypted secrets** | `helm-secrets` (sops) | S3 backup credentials live in `apps/postgres/secrets.yaml` and the Grafana admin password in `apps/victoria-metrics-k8s-stack/secrets.yaml` — both sops-encrypted Helm values, merged by `helm-secrets` at install time. No raw `Secret` manifest ever touches git or the kustomize pipeline. |

---

## Namespace layout

| Namespace | Created by | Contents |
|---|---|---|
| `cnpg-system` | helmfile chart `createNamespace: true` | CNPG operator Deployment + webhooks |
| `cnpg-clusters` | `namespace.yaml` (kustomize) | Postgres `Cluster`, `Pooler`, `ScheduledBackup`, `Service`, `NetworkPolicy`, `Secret` (rendered by chart) |
| `pxc-system` | helmfile chart `createNamespace: true` | PXC operator Deployment |
| `pxc-clusters` | `pxc/namespace.yaml` (kustomize) | `PerconaXtraDBCluster`, HAProxy, backup schedules, `NetworkPolicy`, Tailscale `Service` |
| `rustfs-system` | helmfile chart `createNamespace: true` | RustFS operator Deployment (Tenant CRD controller) |
| `rustfs-clusters` | `rustfs/namespace.yaml` (kustomize) | RustFS `Tenant`, StatefulSets, credentials `Secret`, `NetworkPolicy`, Tailscale `Service` |
| `monitoring` | `monitoring/namespace.yaml` (kustomize) | VMSingle, VMAgent, VMAlert, VMAlertmanager, Grafana, node-exporter, kube-state-metrics, Grafana Tailscale Service |

The `cnpg-clusters` namespace carries `pod-security.kubernetes.io/enforce=restricted`
labels so any pod scheduled there must comply with the PodSecurity restricted
profile. CNPG's pods (operator, instances, PgBouncer) all comply by default.

The `monitoring` namespace uses `pod-security.kubernetes.io/enforce=privileged`
because node-exporter requires `hostNetwork`/`hostPID`/`hostPath` access for
complete host-level metrics collection.

---

## First-time apply

### Prerequisites

- `helmfile` + `helm` + `helm-secrets` plugin installed (system-level toolset
  comes from `profiles/k3s-node.nix`; `helm-secrets` is a one-shot manual
  install — see `docs/k3s-cnpg.md`).
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
   and Tailscale LoadBalancer Services for CNPG, PXC, and RustFS.
2. `helmfile sync` — installs/upgrades all operators (VM stack, CNPG, PXC,
   RustFS) and workloads (Postgres, MySQL). helm-secrets decrypts each
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

### PXC (Percona XtraDB Cluster)

```sh
just k8s::pxc-status               # show PerconaXtraDBCluster status
just k8s::pxc-describe             # detailed cluster description
just k8s::pxc-operator-logs        # tail operator logs
just k8s::pxc-primary-logs         # tail writer node logs
just k8s::pxc-haproxy-logs         # tail HAProxy logs
just k8s::pxc-pods                 # list all PXC pods
just k8s::pxc-backup-list          # list backup objects
just k8s::pxc-backup-now           # trigger on-demand backup
just k8s::pxc-shell                # MySQL CLI via HAProxy
```

### RustFS (S3-compatible object storage)

```sh
just k8s::rustfs-status            # show Tenant status
just k8s::rustfs-describe          # detailed Tenant description
just k8s::rustfs-operator-logs     # tail operator logs
just k8s::rustfs-pod-logs          # tail storage pod logs
just k8s::rustfs-pods              # list all RustFS pods
just k8s::rustfs-pvcs              # list PVCs with capacity
just k8s::rustfs-port-forward      # port-forward S3 API to localhost:9000
just k8s::rustfs-console           # port-forward Console UI to localhost:9001
just k8s::rustfs-health            # test S3 API health
just k8s::rustfs-apply-secret      # apply sops-decrypted credentials
just k8s::rustfs-capacity          # query RustFS cluster capacity
just k8s::rustfs-node-status       # query RustFS node/drive status
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
- `k8s/apps/pxc-operator/secrets.yaml` — PXC operator-side values (empty
  by default)
- `k8s/apps/mysql/secrets.yaml` — S3 backup credentials for PXC
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

The cluster runs `victoria-metrics-k8s-stack` (VMSingle + VMAgent + VMAlert +
VMAlertmanager + Grafana) in the `monitoring` namespace. Key integration points:

- **CNPG instance metrics** — VMPodScrape on port 9187 (defined in
  `clusters/glug-infra/monitoring/cnpg-cluster-vmpodscrape.yaml`)
- **CNPG VMRules** — alerts for replication lag, backup failures, WAL
  archiving, and primary availability
- **PgBouncer metrics** — VMPodScrape on port 9127 (pooler monitoring)
- **CNPG operator metrics** — VMPodScrape on the operator's `/metrics`
  endpoint (defined in `cnpg-operator-vmpodscrape.yaml`)
- **PXC instance metrics** — VMServiceScrape on port 9104 (mysqld_exporter
  sidecar) in `pxc-clusters` namespace
- **PXC HAProxy metrics** — VMServiceScrape on HAProxy stats port in
  `pxc-clusters` namespace
- **PXC VMRules** — alerts for Galera health (wsrep_ready, cluster
  size, flow control), slow queries
- **Grafana dashboards** — the CNPG operator creates a ConfigMap with the
  CloudNativePG dashboard (ID 20417); Grafana's sidecar auto-imports it

Grafana is reachable at `http://grafana.<tailnet>.ts.net:3000` via the
Tailscale LoadBalancer Service in `clusters/glug-infra/monitoring/`.

---

## Stable Postgres endpoint

Webservices connect to:

```
pg-rw.<tailnet>.ts.net:5432
```

For MySQL (PXC):

```
mysql-rw.<tailnet>.ts.net:3306
```

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

### MySQL traffic path

```
webservice
  → mysql-rw.<tailnet>.ts.net:3306   (Tailscale MagicDNS)
  → ts-proxy pod                      (LoadBalancer Service in pxc-clusters)
  → mysql-haproxy Service             (created by PXC operator)
  → HAProxy pods (connection routing)
  → PXC writer node
```

When Galera promotes a new writer the HAProxy health checks detect the change
and re-route within seconds. Webservices see at most a brief connection drop.

### RustFS S3 traffic path

```
client / webservice
  → s3.<tailnet>.ts.net:9000          (Tailscale MagicDNS)
  → ts-proxy pod                       (LoadBalancer Service in rustfs-clusters)
  → RustFS IO Service                  (operator-created, port 9000)
  → RustFS StatefulSet pods            (erasure-coded cluster, 4 servers)
```

RustFS distributes objects across all servers using erasure coding. Any server
can handle any S3 request — the cluster rebalances internally. With 4 servers
and EC:4 parity, the cluster tolerates up to 4 volume failures with no data
loss. On a single node (phase 1), this means drive-level resilience; with
multiple nodes, it provides full node-failure tolerance.

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
├── helmfile.yaml                            # victoria-metrics-k8s-stack + cnpg + pxc + rustfs charts
├── apps/
│   ├── cnpg-operator/
│   │   ├── values.yaml                      # plain Helm values
│   │   └── secrets.yaml                     # sops-encrypted Helm values
│   ├── victoria-metrics-k8s-stack/
│   │   ├── values.yaml                      # VMSingle + VMAgent + Grafana + Alertmanager config
│   │   └── secrets.yaml                     # sops-encrypted Grafana admin password
│   ├── mysql/
│   │   ├── values.yaml                      # PXC cluster + HAProxy + Backup config
│   │   └── secrets.yaml                     # sops-encrypted S3 credentials
│   ├── postgres/
│   │   ├── values.yaml                      # Cluster + Pooler + Backup config
│   │   └── secrets.yaml                     # sops-encrypted S3 credentials
│   ├── pxc-operator/
│   │   ├── values.yaml                      # plain Helm values
│   │   └── secrets.yaml                     # sops-encrypted Helm values
│   ├── rustfs-operator/
│   │   ├── values.yaml                      # RustFS operator Helm values
│   │   └── secrets.yaml                     # sops-encrypted (empty placeholder)
│   └── rustfs/
│       ├── values.yaml                      # Tenant configuration reference
│       └── secrets.yaml                     # sops-encrypted S3 admin credentials
├── clusters/
│   └── glug-infra/
│       ├── kustomization.yaml               # entry point (cnpg-clusters namespace)
│       ├── namespace.yaml                   # cnpg-clusters + PSA labels
│       ├── networkpolicy.yaml               # default-deny + allow rules
│       ├── tailscale-pg-service.yaml        # Tailscale LB: pg-rw
│       ├── pxc/
│       │   ├── kustomization.yaml           # entry point (pxc-clusters namespace)
│       │   ├── namespace.yaml               # pxc-clusters + PSA labels
│       │   ├── networkpolicy.yaml           # default-deny + HAProxy + PXC rules
│       │   └── tailscale-mysql-service.yaml # Tailscale LB: mysql-rw
│       ├── rustfs/
│       │   ├── kustomization.yaml           # entry point (rustfs-clusters namespace)
│       │   ├── namespace.yaml               # rustfs-clusters + PSA restricted labels
│       │   ├── networkpolicy.yaml           # default-deny + S3 + inter-node rules
│       │   ├── credentials-secret.enc.yaml  # RustFS admin credentials (sops-encrypted)
│       │   ├── tenant.yaml                  # RustFS Tenant CR (4 servers × 2 vols)
│       │   └── tailscale-s3-service.yaml    # Tailscale LB: s3
│       └── monitoring/
│           ├── kustomization.yaml           # entry point (monitoring namespace)
│           ├── namespace.yaml               # monitoring + PSA labels
│           ├── tailscale-grafana-service.yaml  # Tailscale LB: grafana
│           ├── cnpg-cluster-vmpodscrape.yaml
│           ├── cnpg-pooler-vmpodscrape.yaml
│           ├── cnpg-operator-vmpodscrape.yaml
│           ├── cnpg-vmrules.yaml
│           ├── pxc-cluster-vmservicescrape.yaml
│           ├── pxc-haproxy-vmservicescrape.yaml
│           ├── pxc-vmrules.yaml
│           ├── pvc-storage-vmrules.yaml
│           ├── laptop-battery-vmrules.yaml
│           ├── zfs-vmrules.yaml
│           ├── zfs-grafana-dashboard.yaml
│           ├── pxc-grafana-dashboard.yaml
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
kubectl -n monitoring get deploy                      # prometheus-operator, grafana, kube-state-metrics
kubectl -n monitoring get pods                         # all Running
kubectl -n monitoring get statefulset                  # prometheus, alertmanager

# Operator is up.
kubectl -n cnpg-system get deploy
kubectl -n cnpg-system get pods                     # 1/1 Running

# CRDs installed.
kubectl get crd | grep cnpg                         # cluster, pooler, backup, scheduledbackup

# Cluster reaches "Cluster in healthy state".
just k8s::cnpg-status                                 # kubectl cnpg status postgres

# All 3 instances Running, exactly one is primary.
kubectl -n cnpg-clusters get pods -l cnpg.io/cluster=postgres -o wide

# PgBouncer pods Running.
kubectl -n cnpg-clusters get pods -l cnpg.io/poolerName=postgres-pooler-rw

# Tailscale ts-proxy pod up; device registered on the tailnet.
kubectl -n tailscale get pods
tailscale status | grep pg-rw

# WAL archiving active (run inside any instance pod).
kubectl exec -n cnpg-clusters -it postgres-1 -- \
  psql -c "SELECT last_archived_wal, last_failed_wal FROM pg_stat_archiver;"

# Trigger an immediate backup; confirm it completes.
just k8s::cnpg-backup-now
just k8s::cnpg-backup-list

# Connect from a tailnet client.
psql "postgres://app:$(kubectl -n cnpg-clusters get secret postgres-app -o jsonpath='{.data.password}' | base64 -d)@pg-rw.<tailnet>.ts.net:5432/app"

# Grafana reachable on the tailnet.
curl -s http://grafana.<tailnet>.ts.net:3000/api/health | jq .

# Prometheus is scraping CNPG metrics.
just k8s::prom-targets | grep cnpg

# CNPG dashboard loaded in Grafana.
curl -s http://grafana.<tailnet>.ts.net:3000/api/search?query=CloudNativePG | jq '.[].title'
```

If any step fails, the `## 6. Day-2 operations` section of
[`docs/k3s-cnpg.md`](../docs/k3s-cnpg.md) maps the most common error strings
(operator OAuth failures, helm-install Job errors, etc.) to fixes.
