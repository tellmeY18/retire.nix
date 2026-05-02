# k8s — Kubernetes resources for the glug-infra cluster

This directory contains all Kubernetes manifests and Helm values for the
`glug-infra` k3s cluster. It is **not** managed by a GitOps controller;
resources are applied manually via `just k8s-apply` from the laptop.

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
| **NixOS bootstrap** | `nh os switch` | k3s itself; OpenEBS ZFS LocalPV CSI driver; the `zfs-localpv` StorageClass; Tailscale Kubernetes operator. Declared via `services.k3s.charts` in `modules/services/k3s.nix` and present on every node the moment k3s starts — no human intervention required after a reboot. |
| **CNPG operator** | `helmfile` | The `cloudnative-pg` chart in the `cnpg-system` namespace. Provides CRDs + the controller. |
| **Postgres workloads** | `helmfile` (cnpg/cluster chart) | One Helm release per Postgres cluster. Renders the `Cluster`, `ScheduledBackup`, and `Pooler` CRs from values files in `apps/postgres/`. |
| **Cluster glue** | `kubectl apply -k` (kustomize) | Namespace (with PSA labels), NetworkPolicies, and the Tailscale LoadBalancer Service. |
| **Encrypted secrets** | `helm-secrets` (sops) | S3 backup credentials live in `apps/postgres/secrets.yaml` as sops-encrypted Helm values, merged by `helm-secrets` at install time. No raw `Secret` manifest ever touches git or the kustomize pipeline. |

---

## Namespace layout

| Namespace | Created by | Contents |
|---|---|---|
| `cnpg-system` | helmfile chart `createNamespace: true` | CNPG operator Deployment + webhooks |
| `cnpg-clusters` | `namespace.yaml` (kustomize) | Postgres `Cluster`, `Pooler`, `ScheduledBackup`, `Service`, `NetworkPolicy`, `Secret` (rendered by chart) |

The `cnpg-clusters` namespace carries `pod-security.kubernetes.io/enforce=restricted`
labels so any pod scheduled there must comply with the PodSecurity restricted
profile. CNPG's pods (operator, instances, PgBouncer) all comply by default.

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
just k8s-apply
```

`just k8s-apply` runs:

1. `helmfile sync` — installs/upgrades the CNPG **operator** and (declared via
   `needs:`) the `postgres` cluster release. helm-secrets decrypts each
   `secrets.yaml` inline and merges it on top of the corresponding `values.yaml`.
2. `kubectl apply -k k8s/clusters/glug-infra` — applies the namespace,
   NetworkPolicies, and Tailscale LoadBalancer Service.

### Preview before applying

```sh
just k8s-diff
```

This runs `helmfile diff` then `kubectl diff -k …`. The kubectl diff exit
code is squashed because absent objects return non-zero on a clean cluster.

---

## Day-2 helpers

```sh
just k8s-cnpg-status              # kubectl cnpg status postgres
just k8s-cnpg-operator-logs       # tail operator logs
just k8s-cnpg-primary-logs        # tail current primary
just k8s-cnpg-backup-now          # on-demand base backup
just k8s-cnpg-backup-list         # list Backup objects with phase
```

For switchover, drain, and restore procedures see [`docs/runbooks/`](docs/runbooks/).

---

## Editing secrets

Secrets live in two places, both as sops-encrypted Helm values files:

- `k8s/apps/postgres/secrets.yaml` — S3 backup credentials
- `k8s/apps/cnpg-operator/secrets.yaml` — operator-side image-pull
  credentials (empty by default)

To edit either:

```sh
just k8s-edit-secret k8s/apps/postgres/secrets.yaml
```

This opens the file in `$EDITOR` via `sops`, which encrypts on save. The
`.sops.yaml` at the repo root defines which age keys are recipients for each
path pattern; both files are covered by the existing `k8s/.../secrets.yaml`
rule (master-key only — no host needs to decrypt these).

---

## Stable Postgres endpoint

Webservices connect to:

```
pg-rw.<tailnet>.ts.net:5432
```

The tailnet hostname is owned by the Tailscale operator and stays registered
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
├── helmfile.yaml                            # cnpg/cloudnative-pg + cnpg/cluster releases
├── apps/
│   ├── cnpg-operator/
│   │   ├── values.yaml                      # plain Helm values
│   │   └── secrets.yaml                     # sops-encrypted Helm values
│   └── postgres/
│       ├── values.yaml                      # Cluster + Pooler + Backup config
│       └── secrets.yaml                     # sops-encrypted S3 credentials
├── clusters/
│   └── glug-infra/
│       ├── kustomization.yaml               # entry point
│       ├── namespace.yaml                   # cnpg-clusters + PSA labels
│       ├── networkpolicy.yaml               # default-deny + allow rules
│       └── tailscale-pg-service.yaml        # Tailscale LoadBalancer Service
└── docs/
    └── runbooks/
        ├── failover.md
        ├── restore-pitr.md
        └── add-node.md
```

---

## Verifying a healthy install

After the first `just k8s-apply`, walk through these checks:

```sh
# Operator is up.
kubectl -n cnpg-system get deploy
kubectl -n cnpg-system get pods                     # 1/1 Running

# CRDs installed.
kubectl get crd | grep cnpg                         # cluster, pooler, backup, scheduledbackup

# Cluster reaches "Cluster in healthy state".
just k8s-cnpg-status                                 # kubectl cnpg status postgres

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
just k8s-cnpg-backup-now
just k8s-cnpg-backup-list

# Connect from a tailnet client.
psql "postgres://app:$(kubectl -n cnpg-clusters get secret postgres-app -o jsonpath='{.data.password}' | base64 -d)@pg-rw.<tailnet>.ts.net:5432/app"
```

If any step fails, the `## 6. Day-2 operations` section of
[`docs/k3s-cnpg.md`](../docs/k3s-cnpg.md) maps the most common error strings
(operator OAuth failures, helm-install Job errors, etc.) to fixes.
