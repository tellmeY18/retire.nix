# k8s — Kubernetes resources for the chopper cluster

This directory contains all Kubernetes manifests and Helm values for the
production-grade k3s cluster running on `chopper`.  It is **not** managed by a
GitOps controller; resources are applied manually via `just k8s-apply` (or the
individual steps below) from the laptop.

---

## Architecture split: Nix vs helmfile

| Layer | Managed by | What lives there |
|---|---|---|
| **NixOS bootstrap** | `nixos-rebuild` / `nh os switch` | k3s itself, OpenEBS ZFS LocalPV operator, Tailscale Kubernetes operator.  These are declared via `services.k3s.charts` in `modules/services/k3s.nix` and are present on the node the moment k3s starts — no human intervention required after a reboot. |
| **Cluster operators** | `helmfile` (this directory) | CNPG operator (`cloudnative-pg`).  Installed once; upgraded by bumping the chart version here and re-running `just k8s-apply`. |
| **Cluster workloads** | `kubectl apply -k` (kustomize) | The CNPG `Cluster`, `Pooler`, `ScheduledBackup`, `ObjectStore`, and the Tailscale LoadBalancer `Service` for PostgreSQL. |
| **Encrypted secrets** | `sops --decrypt \| kubectl apply -f -` | S3 credentials for Barman backups.  Never go through kustomize — applied separately so plaintext never touches a manifest pipeline. |

---

## Namespace layout

| Namespace | Contents |
|---|---|
| `cnpg-system` | CNPG operator deployment |
| `cnpg-clusters` | `Cluster`, `Pooler`, `ScheduledBackup`, `ObjectStore`, all related Secrets |

---

## First-time apply

### Prerequisites

- `helmfile` + `helm` + `helm-secrets` plugin installed (available in the
  `devShells.default` defined in `flake.nix`).
- `kubectl` configured against the chopper cluster (`KUBECONFIG` set or
  `~/.kube/config` populated).
- `sops` on `$PATH`; your age private key loaded (see `docs/secrets.md`).
- The S3 backup bucket already created and credentials at hand.

### Steps

```shell
# 1. Encrypt the backup-S3 secret (first time only — do NOT commit plaintext)
cp k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml /tmp/cnpg-backup-s3.yaml
# Edit /tmp/cnpg-backup-s3.yaml, fill in real ACCESS_KEY_ID / SECRET_ACCESS_KEY
# then encrypt in-place:
just k8s-edit-secret k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml

# 2. Update the destinationPath in cnpg-cluster.yaml to match your S3 bucket.

# 3. Apply everything
just k8s-apply
```

`just k8s-apply` runs three steps in order:

1. `helmfile sync` — installs/upgrades the CNPG operator chart.
2. `kubectl apply -k k8s/clusters/chopper` — applies the Cluster, Pooler,
   ScheduledBackup, ObjectStore, and Tailscale Service.
3. `sops --decrypt ... | kubectl apply -f -` — decrypts and applies every
   `*.enc.yaml` in `k8s/clusters/chopper/secrets/`.

### Preview before applying

```shell
just k8s-diff
```

---

## Editing secrets

All secrets under `k8s/**/secrets/` and `k8s/**/secrets.yaml` **must** be
sops-encrypted before being committed.  The naming convention is:

- `*.enc.yaml` — sops-encrypted Kubernetes `Secret` manifests applied via
  `sops --decrypt | kubectl apply -f -` (NOT through kustomize).
- `secrets.yaml` next to a Helm values file — sops-encrypted Helm values,
  decrypted at install time by `helm-secrets` when referenced with the
  `secrets://` prefix in `helmfile.yaml`.

To create or edit a secret:

```shell
just k8s-edit-secret k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml
```

This opens the file in `$EDITOR` via `sops`, which handles
encrypt-on-save automatically.

To encrypt a new file for the first time:

```shell
sops --encrypt --in-place <path-to-file>
```

The `.sops.yaml` at the repo root defines which age keys are used as
recipients for each path pattern.

---

## Stable Postgres endpoint

Webservices connect to:

```
pg-rw.<tailnet>.ts.net:5432
```

This hostname is owned by the Tailscale operator, which keeps it registered
as long as the cluster is running.  Traffic flows:

```
webservice
  → pg-rw.<tailnet>.ts.net:5432  (Tailscale MagicDNS)
  → Tailscale ts-proxy pod  (LoadBalancer Service in cnpg-clusters)
  → chopper-pg-pooler-rw Service  (CNPG Pooler)
  → PgBouncer pods (transaction mode)
  → chopper-pg-rw Service  (always the current CNPG primary)
  → PostgreSQL primary pod
```

See `docs/k3s-cnpg.md` for the full HA topology and the 2-node etcd
quorum warning.

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
├── README.md                         # this file
├── helmfile.yaml                     # CNPG operator chart pin
├── apps/
│   └── cnpg-operator/
│       ├── values.yaml               # Helm values (plain)
│       └── secrets.yaml              # Helm values (sops-encrypted)
├── clusters/
│   └── chopper/
│       ├── kustomization.yaml        # kustomize entry-point (no secrets)
│       ├── cnpg-cluster.yaml         # CNPG Cluster CR
│       ├── cnpg-pooler.yaml          # CNPG Pooler CR (PgBouncer)
│       ├── cnpg-backup.yaml          # ScheduledBackup + ObjectStore CRs
│       ├── tailscale-pg-service.yaml # Tailscale LoadBalancer Service
│       └── secrets/
│           └── cnpg-backup-s3.enc.yaml  # sops-encrypted S3 credentials
└── docs/
    └── runbooks/
        ├── failover.md
        ├── restore-pitr.md
        └── add-node.md
```
