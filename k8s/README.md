# k8s — Kubernetes resources for the chopper cluster

This directory contains all Kubernetes manifests and Helm values for the
production-grade k3s cluster running on `chopper`. It is **not** managed by a
GitOps controller; resources are applied manually via `just k8s-apply` (or the
individual steps below) from the laptop.

> See [`docs/k3s-cnpg.md`](../docs/k3s-cnpg.md) for the full architecture,
> including the HA reality-check (the 2-node etcd quorum trap), Tailscale ACL
> requirements, and secret-management model.

---

## Architecture split: Nix vs helmfile vs kustomize

| Layer | Managed by | What lives there |
|---|---|---|
| **NixOS bootstrap** | `nixos-rebuild` / `nh os switch` | k3s itself, OpenEBS ZFS LocalPV operator, Tailscale Kubernetes operator. Declared via `services.k3s.charts` in `modules/services/k3s.nix` and present on the node the moment k3s starts — no human intervention required after a reboot. |
| **Cluster operator** | `helmfile` (this directory) | CNPG operator (`cloudnative-pg`). Installed once; upgraded by bumping the chart version and re-running `just k8s-apply`. |
| **Cluster workloads** | `kubectl apply -k` (kustomize) | Namespace, NetworkPolicies, the CNPG `Cluster`, `Pooler`, `ScheduledBackup`, the Tailscale LoadBalancer `Service`, and a `PodDisruptionBudget` for the pooler. |
| **Encrypted secrets** | `sops --decrypt \| kubectl apply -f -` | S3 credentials for Barman backups. Never go through kustomize — applied separately so plaintext never touches a manifest pipeline. |

---

## Namespace layout

| Namespace | Created by | Contents |
|---|---|---|
| `cnpg-system` | helmfile chart `createNamespace: true` | CNPG operator Deployment + webhooks |
| `cnpg-clusters` | `namespace.yaml` (kustomize) | `Cluster`, `Pooler`, `ScheduledBackup`, `PodDisruptionBudget`, `Service`, `NetworkPolicy`, `Secret` (sops-applied) |

The `cnpg-clusters` namespace carries `pod-security.kubernetes.io/enforce=restricted`
labels so any pod scheduled there must comply with the PodSecurity restricted
profile. CNPG's pods (operator, instances, PgBouncer) all comply by default.

---

## First-time apply

### Prerequisites

- `helmfile` + `helm` + `helm-secrets` plugin installed (the system-level
  toolset is provided by `profiles/k3s-node.nix`; `helm-secrets` is a
  one-shot manual install — see `docs/k3s-cnpg.md`).
- `kubectl` configured against the chopper cluster. On chopper itself this
  is automatic via `KUBECONFIG=/etc/rancher/k3s/k3s.yaml` exported by
  `profiles/k3s-node.nix`.
- `sops` on `$PATH`; your age private key loaded (see
  [`docs/secrets.md`](../docs/secrets.md)).
- The S3 backup bucket already created and credentials at hand.
- The `kubectl-cnpg` plugin: `kubectl krew install cnpg`.

### Steps

```sh
# 1. Encrypt the backup-S3 secret (first time only — never commit plaintext).
#    Open the placeholder file in $EDITOR via sops, fill in real values,
#    save & exit — sops re-encrypts in place.
just k8s-edit-secret k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml

# 2. Update the bucket path in cnpg-cluster.yaml:
#       spec.backup.barmanObjectStore.destinationPath
#    (and uncomment endpointURL if using non-AWS S3).

# 3. Apply everything.
just k8s-apply
```

`just k8s-apply` runs three steps in order:

1. `helmfile sync` — installs/upgrades the CNPG operator chart (and its
   CRDs) in the `cnpg-system` namespace. Must be first because the
   `Cluster` CR in step 2 will fail apply if its CRD is not yet present.
2. `kubectl apply -k k8s/clusters/chopper` — applies the namespace,
   NetworkPolicies, Cluster, Pooler+PDB, ScheduledBackup, and Tailscale
   Service in `cnpg-clusters`.
3. `sops --decrypt … | kubectl apply -f -` — decrypts and applies every
   `*.enc.yaml` in `k8s/clusters/chopper/secrets/`. Uses bash `nullglob`
   so an empty/missing secrets directory is a no-op rather than an error.

### Preview before applying

```sh
just k8s-diff
```

This runs `helmfile diff` then `kubectl diff -k …` and is safe on a clean
cluster (the `kubectl diff` exit code is squashed because absent objects
return non-zero).

---

## Day-2 helpers

The `Justfile` exposes shortcuts so you don't need to remember the namespace
on every command:

```sh
just k8s-cnpg-status              # kubectl cnpg status chopper-pg
just k8s-cnpg-operator-logs       # tail operator logs
just k8s-cnpg-primary-logs        # tail current primary
just k8s-cnpg-backup-now          # on-demand base backup
just k8s-cnpg-backup-list         # list Backup objects with phase
```

For switchover, drain, and restore procedures see
[`k8s/docs/runbooks/`](docs/runbooks/).

---

## Editing secrets

All secrets under `k8s/**/secrets/` and `k8s/**/secrets.yaml` **must** be
sops-encrypted before being committed. The naming convention is:

- `*.enc.yaml` — sops-encrypted Kubernetes `Secret` manifests applied via
  `sops --decrypt | kubectl apply -f -` (NOT through kustomize).
- `secrets.yaml` next to a Helm values file — sops-encrypted Helm values,
  decrypted at install time by `helm-secrets` when referenced with the
  `secrets://` prefix in `helmfile.yaml`.

To create or edit a secret:

```sh
just k8s-edit-secret k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml
```

This opens the file in `$EDITOR` via `sops`, which encrypts on save.

To encrypt a brand-new file for the first time:

```sh
sops --encrypt --in-place <path-to-file>
```

The `.sops.yaml` at the repo root defines which age keys are recipients
for each path pattern.

---

## Stable Postgres endpoint

Webservices connect to:

```
pg-rw.<tailnet>.ts.net:5432
```

This hostname is owned by the Tailscale operator, which keeps it registered
as long as the cluster is running. Traffic flows:

```
webservice
  → pg-rw.<tailnet>.ts.net:5432  (Tailscale MagicDNS)
  → ts-proxy pod                  (LoadBalancer Service in cnpg-clusters)
  → chopper-pg-pooler-rw Service  (CNPG Pooler)
  → PgBouncer pods (transaction mode)
  → chopper-pg-rw Service         (always points at current primary)
  → PostgreSQL primary pod
```

Failover behaviour: when CNPG promotes a new primary, the `chopper-pg-rw`
Service endpoints are updated within seconds; PgBouncer reconnects on its
own. Webservices see at most a brief connection-pool churn.

The Tailscale Service has `sessionAffinity: ClientIP` so a single
webservice stays pinned to one PgBouncer pod for the lifetime of its
connection pool — purely a latency optimisation; PgBouncer is stateless
across pods, so a sudden re-pinning is also harmless.

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
├── helmfile.yaml                            # CNPG operator chart pin (0.28.0)
├── apps/
│   └── cnpg-operator/
│       ├── values.yaml                      # plain Helm values
│       └── secrets.yaml                     # encrypted Helm values (sops)
├── clusters/
│   └── chopper/
│       ├── kustomization.yaml               # entry point (no secrets)
│       ├── namespace.yaml                   # cnpg-clusters + PSA labels
│       ├── networkpolicy.yaml               # default-deny + allow-rules
│       ├── cnpg-cluster.yaml                # Cluster CR (3 instances, sync rep)
│       ├── cnpg-pooler.yaml                 # Pooler CR + PodDisruptionBudget
│       ├── cnpg-backup.yaml                 # ScheduledBackup CR (daily 02:00 UTC)
│       ├── tailscale-pg-service.yaml        # Tailscale LoadBalancer Service
│       └── secrets/
│           └── cnpg-backup-s3.enc.yaml      # sops-encrypted S3 credentials
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
just k8s-cnpg-status                                 # kubectl cnpg status

# All 3 instances Running, exactly one is primary.
kubectl -n cnpg-clusters get pods -l cnpg.io/cluster=chopper-pg -o wide

# PgBouncer pods Running.
kubectl -n cnpg-clusters get pods -l cnpg.io/poolerName=chopper-pg-pooler-rw

# Tailscale ts-proxy pod up; device registered on the tailnet.
kubectl -n tailscale get pods
tailscale status | grep pg-rw

# WAL archiving active (run inside any instance pod).
kubectl exec -n cnpg-clusters -it chopper-pg-1 -- \
  psql -c "SELECT last_archived_wal, last_failed_wal FROM pg_stat_archiver;"

# Trigger an immediate backup; confirm it completes.
just k8s-cnpg-backup-now
just k8s-cnpg-backup-list

# Connect from a tailnet client.
psql "postgres://app:$(kubectl -n cnpg-clusters get secret chopper-pg-app -o jsonpath='{.data.password}' | base64 -d)@pg-rw.<tailnet>.ts.net:5432/app"
```

If any step fails, the `## 6. Day-2 operations` section of
[`docs/k3s-cnpg.md`](../docs/k3s-cnpg.md) maps the most common error
strings (operator OAuth failures, helm-install Job errors, etc.) to fixes.
