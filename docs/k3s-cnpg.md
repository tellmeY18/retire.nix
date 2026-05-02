# k3s + CloudNativePG on chopper

> **Status:** design document — implementation in progress (see ROADMAP.md M10–M12).
> The NixOS module (`modules/services/k3s.nix`) and Kubernetes manifests
> (`k8s/`) are written by the k3s agent; this document describes the
> architecture those files implement.

---

## Table of contents

1. [Overview](#1-overview)
2. [Architecture diagram](#2-architecture-diagram)
3. [HA reality check](#3-ha-reality-check)
4. [Node roles](#4-node-roles)
5. [Secret management](#5-secret-management)
6. [Day-2 operations](#6-day-2-operations)
7. [Backup and restore](#7-backup-and-restore)
8. [Adding a node](#8-adding-a-node)
9. [Monitoring and alerting](#9-monitoring-and-alerting)
10. [Tailscale ACL requirements](#10-tailscale-acl-requirements)

---

## 1. Overview

This cluster runs a **production-grade PostgreSQL service** on `chopper` (an
x86_64 laptop running NixOS with a ZFS root). PostgreSQL is managed by
[CloudNativePG (CNPG)](https://cloudnative-pg.io/) — a Kubernetes operator
that handles provisioning, replication, failover, and backup.

The cluster is **not** a general-purpose Kubernetes platform. It exists for one
purpose: to expose a stable, highly-available `postgres://` endpoint that cloud
webservices can reach over [Tailscale](https://tailscale.com/).

### Stable connection target

```
pg-rw.<tailnet>.ts.net:5432
```

This hostname is owned by the Tailscale Kubernetes operator and always points
at the current CNPG primary (via PgBouncer → CNPG `-rw` Service). It does not
change when the primary pod restarts, when a failover occurs, or when a k3s
node is rescheduled. Cloud webservices connect only to this address.

### What lives where

| Component | Host | Technology |
|---|---|---|
| k3s control plane | chopper (later: all nodes) | k3s embedded etcd |
| PostgreSQL | chopper (later: spread across nodes) | CNPG Cluster (3 instances) |
| Storage | chopper | OpenEBS ZFS LocalPV on `rpool/openebs` |
| Stable PG endpoint | Tailnet | Tailscale k8s operator + PgBouncer Pooler |
| Off-site backups | Backblaze B2 / Cloudflare R2 | Barman Cloud (CNPG built-in) |
| Warm backups | chopper | Barman Cloud → Garage (local S3) |
| GitOps | n/a | None — `helmfile` + `kubectl` from the laptop |

---

## 2. Architecture diagram

```
 ┌──────────────────────────────────────────────────────────────────────┐
 │  Cloud (VPS / serverless)                                            │
 │                                                                      │
 │   webservice-A ──┐                                                   │
 │   webservice-B ──┤─── postgres://pg-rw.<tailnet>.ts.net:5432         │
 │   webservice-C ──┘                    │                              │
 └───────────────────────────────────────┼──────────────────────────────┘
                                         │  Tailscale WireGuard tunnel
                     ┌───────────────────▼──────────────────────────┐
                     │  Tailnet (encrypted overlay)                  │
                     │                                               │
                     │   MagicDNS: pg-rw.<tailnet>.ts.net            │
                     │         │                                     │
                     └─────────┼─────────────────────────────────────┘
                               │ port 5432
                 ┌─────────────▼─────────────────────────────────────────┐
                 │  k3s cluster (chopper, + future nodes)                 │
                 │                                                        │
                 │  ┌──────────────────────────────────────────────────┐ │
                 │  │  Tailscale operator (StatefulSet ts-proxy)        │ │
                 │  │  Service type: LoadBalancer  (tailscale class)    │ │
                 │  └──────────────────┬───────────────────────────────┘ │
                 │                     │ forwards to                      │
                 │  ┌──────────────────▼───────────────────────────────┐ │
                 │  │  PgBouncer Pooler  (CNPG Pooler CRD)             │ │
                 │  │  transaction mode, Service: cnpg-cluster-pooler  │ │
                 │  └──────────────────┬───────────────────────────────┘ │
                 │                     │ forwards to                      │
                 │  ┌──────────────────▼───────────────────────────────┐ │
                 │  │  CNPG -rw Service  (always → current primary)    │ │
                 │  └──────────────────┬───────────────────────────────┘ │
                 │                     │                                  │
                 │         ┌───────────▼────────────────────────────┐    │
                 │         │  CNPG Cluster (3 instances)            │    │
                 │         │                                        │    │
                 │         │  ┌────────────┐  ┌────────────┐       │    │
                 │         │  │ primary    │  │ replica-1  │  ...  │    │
                 │         │  │ (postgres) │◄─│ (streaming │       │    │
                 │         │  └─────┬──────┘  │  repl)     │       │    │
                 │         │        │         └────────────┘       │    │
                 │         │  ┌─────▼──────┐                       │    │
                 │         │  │  ZFS       │  ← OpenEBS LocalPV    │    │
                 │         │  │  LocalPV   │    PVC per instance    │    │
                 │         │  │  PVC       │    on rpool/openebs    │    │
                 │         │  └────────────┘                       │    │
                 │         └────────────────────────────────────────┘    │
                 │                                                        │
                 │  WAL archiving (continuous) ──► Barman Cloud          │
                 │                                    ├── Garage (local) │
                 │                                    └── B2/R2 (remote) │
                 └────────────────────────────────────────────────────────┘
```

**Failover path (happy path):** if the primary pod dies, CNPG promotes the
sync replica in seconds. The `-rw` Service endpoints update automatically.
PgBouncer holds frontend connections briefly and retries; webservices see a
brief blip but recover without operator intervention.

**Failover path (node dies):** if the node hosting the primary pod dies, k3s
reschedules the replica pods (if another node is available), CNPG promotes a
new primary, and the ts-proxy pod is also rescheduled. `pg-rw.ts.net` resumes
pointing at the new primary. **This only works with 3+ nodes.** See § 3 below.

---

## 3. HA reality check

Read this section before deploying. The behaviour of this cluster at each
topology stage is materially different. Do not assume "2 nodes = HA."

### Phase 1 — 1 node (today, `chopper` only)

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  WARNING: No high availability.                          │
│  If chopper goes down, the cluster goes down.            │
│                                                          │
│  The three CNPG instances all run on the same node.      │
│  Pod restarts (not node loss) are handled by CNPG.       │
│  Off-site backups (Barman → B2/R2) are the only DR.      │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

- etcd: single node, no quorum concerns (1 member = always healthy).
- CNPG: 3 pods on one node. Primary pod failure → CNPG promotes a local
  replica (seconds). Node failure → all pods gone, cluster unreachable.
- Recovery: `nixos-rebuild` / reboot restores k3s and CNPG. ZFS local data
  is intact. The PITR window covers anything not yet flushed to off-site.
- **Acceptable for development and personal use. Not acceptable for
  production SLAs.**

### Phase 2 — 2 nodes

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WARNING: ⚠ ETCD SPLIT-BRAIN TRAP. 2-node is NOT safe HA.      │
│                                                                  │
│  etcd requires an ODD quorum. With 2 members, losing EITHER     │
│  node makes the cluster read-only (etcd loses quorum). The      │
│  Kubernetes API server becomes unavailable. CNPG cannot         │
│  safely promote a new primary without a healthy API server.     │
│                                                                  │
│  A 2-node cluster is more fragile than a 1-node cluster in      │
│  certain failure modes, not less.                               │
│                                                                  │
│  Use 2-node only as a temporary stepping stone to 3 nodes.      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

- CNPG pods *can* spread across 2 nodes with pod anti-affinity, which
  means a primary pod failure + rescheduling works.
- But a full node loss takes the etcd cluster below quorum and halts the
  Kubernetes control plane. No new pods can be scheduled. No failover.
- **Do not run 2-node in production.**

### Phase 3 — 3 nodes (target topology)

This is the minimum for the promise "survives any one host going down."

```
  chopper (server-init)   +   node-2 (server)   +   node-3 (quorum)
       etcd member 1              etcd member 2         etcd member 3
       CNPG primary               CNPG replica-1        (tainted: no workloads)
       ts-proxy (replica)         CNPG replica-2        ts-proxy (primary)
```

- etcd: 3 members → quorum = 2. One node loss → cluster stays healthy.
- CNPG: 3 instances spread by `podAntiAffinity: requiredDuringScheduling`
  on `kubernetes.io/hostname`. One node loss → at most 1 instance lost,
  CNPG promotes a surviving replica.
- ts-proxy: 2 replicas with anti-affinity. One node loss → rescheduled.
- The quorum node (`node-3`) is tainted
  `node-role.kubernetes.io/control-plane:NoSchedule` and
  `quorum-only=true:NoExecute` so no workloads (including CNPG) land on it.
  It can be a cheap, always-on VPS, a Raspberry Pi, or a home-server VM.

---

## 4. Node roles

The `modules/services/k3s.nix` module exposes a `role` option:

| Role | `services.k3s-cluster.role` | Description |
|---|---|---|
| `server-init` | First control-plane node. Sets `--cluster-init` to initialise the embedded etcd cluster. **Only one node should ever have this role.** |
| `server` | Additional control-plane node. Joins the etcd cluster via `--server`. Used for node-2 in Phase 3. |
| `agent` | Worker-only node. No etcd membership. Does not run the kube-apiserver. For future high-memory workload nodes. |
| `quorum` | Alias for `server`, but the NixOS module additionally applies taints so no workloads schedule here. For node-3 in Phase 3. |

All traffic (inter-node etcd peers, kubelet, flannel overlay, apiserver) is
bound to `tailscale0`. Public interfaces are firewalled for k3s ports.

### Bootstrap sequence

1. `chopper` boots with `role = "server-init"`.
   k3s starts, etcd initialises, `/var/lib/rancher/k3s/server/node-token` is
   populated. The k3s token is also available at `/run/secrets/k3s-token`
   (sops-nix-decrypted). Bootstrap manifests (OpenEBS, Tailscale operator)
   are applied automatically from `/var/lib/rancher/k3s/server/manifests/`.
2. After `pg-rw.<tailnet>.ts.net` is resolvable, deploy CNPG operator and
   Cluster via `just k8s-apply`.
3. When adding node-2 or node-3, set `role = "server"` or `"quorum"` and
   point `serverAddr` at `https://chopper.<tailnet>.ts.net:6443`.

---

## 5. Secret management

Secrets follow the two-tier model documented in `.sops.yaml`. Here is how each
secret flows from source to consumer:

### Tier 1 — NixOS-side (sops-nix)

These are decrypted automatically at NixOS activation. No operator action
required after initial setup.

#### `secrets/chopper/k3s-token`

```
Git (sops-encrypted)
  → sops-nix activation
  → /run/secrets/k3s-token  (tmpfs, mode 0400)
  → services.k3s-cluster.tokenFile = "/run/secrets/k3s-token"
  → k3s --token-file /run/secrets/k3s-token
```

All nodes joining the cluster must share the same token. If you add a new
node, the same sops-encrypted file must be present (or re-encrypted) for
that host's key.

#### `secrets/chopper/tailscale-operator-oauth`

```
Git (sops-encrypted)
  → sops-nix activation
  → /run/secrets/tailscale-operator-oauth  (tmpfs)
  → systemd oneshot reads TAILSCALE_OPERATOR_CLIENT_ID /
    TAILSCALE_OPERATOR_CLIENT_SECRET
  → renders a Kubernetes Secret manifest in memory
  → writes it to /var/lib/rancher/k3s/server/manifests/
    tailscale-oauth-secret.yaml  (NOT the Nix store — which is world-readable)
  → k3s picks it up, creates the Secret in the cluster
  → Tailscale operator reads the Secret for its OAuth flow
```

**Important:** the rendered manifest path (`/var/lib/rancher/k3s/server/
manifests/tailscale-oauth-secret.yaml`) is ephemeral. It is regenerated on
every boot by the systemd oneshot. Never commit a plain-text copy.

#### Other existing Tier-1 secrets (`secrets/chopper/secrets.yaml`)

Tailscale auth key, Nextcloud admin password, Cloudflared tunnel credentials.
See `docs/secrets.md` for the full workflow.

### Tier 2 — Cluster-side (laptop apply)

These are decrypted by the operator's laptop and applied via `just k8s-apply`.
Cluster nodes never hold the decrypt keys for these.

#### `k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml`

```
Git (sops-encrypted Kubernetes Secret manifest)
  → just k8s-apply
  → sops --decrypt | kubectl apply -f -
  → Secret in cluster: cnpg-backup-s3-creds
  → CNPG ObjectStore references it as secretRef
  → Barman Cloud uses it to push WAL + base backups to B2/R2
```

#### `k8s/apps/*/secrets.yaml` (Helm values)

```
Git (sops-encrypted Helm values)
  → helmfile (helm-secrets plugin)
  → sops --decrypt inline during helm install/upgrade
  → values injected into Helm chart
```

### CNPG-managed secrets (no operator input required)

CNPG generates and manages the PostgreSQL user credentials entirely inside
the cluster:

| Secret name | Contents | Used by |
|---|---|---|
| `<cluster>-superuser` | `postgres` superuser username + password | DBA access only |
| `<cluster>-app` | Application DB username + password | Webservices |

Fetch the connection string once at webservice deploy time:

```sh
kubectl get secret chopper-pg-app -n cnpg \
  -o jsonpath='{.data.uri}' | base64 -d
```

---

## 6. Day-2 operations

### Check cluster health

```sh
# Node status
kubectl get nodes -o wide

# All pods across all namespaces
kubectl get pods -A

# CNPG cluster overview (requires kubectl-cnpg plugin)
kubectl cnpg status chopper-pg -n cnpg

# Check CNPG cluster events
kubectl describe cluster chopper-pg -n cnpg

# Check etcd health (on a server node)
# k3s bundles etcdctl:
k3s etcd-snapshot list
```

### Check replication lag

```sh
# Via kubectl-cnpg
kubectl cnpg status chopper-pg -n cnpg | grep -A5 "Streaming Replication"

# Directly in PostgreSQL
kubectl exec -it chopper-pg-1 -n cnpg -- \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# Replica-side lag
kubectl exec -it chopper-pg-2 -n cnpg -- \
  psql -U postgres -c "SELECT now() - pg_last_xact_replay_timestamp() AS lag;"
```

### Trigger a manual CNPG switchover

A switchover gracefully promotes a replica to primary. Use this for planned
maintenance (node reboot, k3s upgrade, etc.):

```sh
# Promote chopper-pg-2 to primary
kubectl cnpg promote chopper-pg chopper-pg-2 -n cnpg

# Watch progress (the old primary demotes, new one accepts writes)
kubectl get pods -n cnpg -w
```

After the switchover, the `-rw` Service automatically retargets the new
primary. PgBouncer handles the connection drain transparently.

### Rotate the k3s join token

The k3s token cannot be hot-rotated without restarting all nodes. Plan a
maintenance window:

```sh
# 1. Generate a new token
openssl rand -hex 32

# 2. Edit the sops-encrypted secret
sops secrets/chopper/k3s-token

# 3. Rebuild and switch chopper first (it is the server-init node)
nh os switch -- --target-host chopper

# 4. Restart k3s on all other nodes sequentially
# (done automatically by the NixOS k3s module on next rebuild/reboot)
```

### Update Tailscale operator OAuth client

```sh
# 1. Rotate the OAuth client in Tailscale admin console
#    https://login.tailscale.com/admin/settings/oauth

# 2. Edit the sops-encrypted secret
sops secrets/chopper/tailscale-operator-oauth

# 3. Rebuild chopper — the systemd oneshot re-renders the Secret manifest
nh os switch -- --target-host chopper

# 4. Restart the Tailscale operator to pick up the new Secret
kubectl rollout restart deployment/operator -n tailscale
```

### Access the Kubernetes API

There are three contexts in which you'll want `kubectl`: directly on the
cluster node (`chopper`), from a remote admin machine over Tailscale, and
for the bundled `helm-install-*` jobs that k3s runs internally. All three
are covered below.

#### From `chopper` itself (out-of-the-box)

The k3s NixOS module (`modules/services/k3s.nix`) and the
`profiles/k3s-node.nix` role together arrange for kubectl to Just Work for
any user in the `wheel` group:

- k3s is started with `--write-kubeconfig-mode=0640`, and a tmpfiles rule
  chgrp's `/etc/rancher/k3s/k3s.yaml` to `wheel`. Members of `wheel` can
  read the kubeconfig without `sudo`.
- The profile exports `KUBECONFIG=/etc/rancher/k3s/k3s.yaml` system-wide via
  `environment.variables`, so `kubectl`, `helm`, `helmfile`, `k9s`, and
  `cmctl` all pick it up automatically on login.
- `kubectl`, `helm`, `helmfile`, `k9s`, and `sops` are installed at the
  system level by the profile, plus a richer set (including aliases
  `k`, `kns`, `kctx`) at the user level by `home/common/packages/dev-k8s.nix`.

**First-time verification after `nh os switch`:**

```sh
# 1. The KUBECONFIG env var only reaches NEW login sessions.
#    Re-login, OR refresh the current shell:
exec $SHELL -l
echo $KUBECONFIG     # → /etc/rancher/k3s/k3s.yaml

# 2. Sanity-check the cluster:
kubectl get nodes                        # NAME=chopper, STATUS=Ready
kubectl get pods -A                      # kube-system, openebs, tailscale
kubectl get storageclass                 # zfs-localpv (default)
kubectl get helmcharts -A                # both bootstrap charts present
```

**If `kubectl` still says `connection refused` to `localhost:8080`:**

That error is the smoking gun for `KUBECONFIG` not being set in the
current process. Run any of:

```sh
# (a) one-shot for the current command:
KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes

# (b) one-shot for the current shell:
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# (c) bypass kubectl entirely — k3s ships its own embedded kubectl that
#     reads the kubeconfig as root:
sudo k3s kubectl get nodes
sudo k3s kubectl logs -n kube-system job.batch/helm-install-tailscale-operator
```

Option (c) is the canonical "is the cluster actually up?" probe — it works
even if `KUBECONFIG`, file permissions, or the `wheel` group membership
are misconfigured.

**If `kubectl get nodes` returns `permission denied` reading the
kubeconfig:**

```sh
# Confirm file mode and group:
ls -l /etc/rancher/k3s /etc/rancher/k3s/k3s.yaml
#    drwxr-s--- 2 root wheel ...   /etc/rancher/k3s        ← note the `s`
#    -rw-r----- 1 root wheel ...   /etc/rancher/k3s/k3s.yaml

# Confirm your user is in wheel:
id -nG | tr ' ' '\n' | grep -x wheel

# If the file is still 0600 root:root, the system was rebuilt but k3s was
# already running with the old flags. Force it to rewrite by restarting:
sudo systemctl restart k3s
sudo systemd-tmpfiles --create

# As a one-shot manual fix without rebuilding (survives only until next
# k3s restart, after which the tmpfiles rule + setgid dir takes over):
sudo chmod g+s /etc/rancher/k3s
sudo chgrp wheel /etc/rancher/k3s /etc/rancher/k3s/k3s.yaml
sudo chmod 0640 /etc/rancher/k3s/k3s.yaml
```

#### Inspecting the bootstrap HelmChart jobs

k3s renders our `services.k3s.manifests.helmchart-*` entries into
`HelmChart` CRs in `kube-system`. Each one creates a one-shot Job called
`helm-install-<name>` that runs the actual `helm install` and writes its
logs into the Job pod. To inspect them:

```sh
# List both bootstrap charts and their phase:
kubectl get helmcharts -A

# Watch the install Job for the Tailscale operator:
kubectl -n kube-system get jobs | grep helm-install
kubectl -n kube-system logs job/helm-install-tailscale-operator -f
kubectl -n kube-system logs job/helm-install-openebs-zfs-localpv -f

# If a Job is stuck or failed, describe it for events:
kubectl -n kube-system describe job helm-install-tailscale-operator
```

**Forcing a HelmChart to re-run after fixing a chart pin.** k3s's HelmChart
controller does not re-run a failed install Job just because the
`HelmChart` CR's `spec.version` (or `valuesContent`) changed. After
`nh os switch`-ing a fix, delete the failed Job so the controller
recreates it with the new spec:

```sh
# Delete the failed install Job (the controller recreates it):
kubectl -n kube-system delete job helm-install-tailscale-operator

# Watch the new attempt:
kubectl -n kube-system get jobs -w | grep helm-install-tailscale-operator
kubectl -n kube-system logs -f job/helm-install-tailscale-operator
```

If a chart version was pinned to a tag that the upstream repo never
published (Tailscale, for example, has historically skipped some `x.y.0`
patches — always cross-check `https://pkgs.tailscale.com/helmcharts/index.yaml`),
you'll see this in the install Job logs:

```
Error: INSTALLATION FAILED: chart "tailscale-operator" matching X.Y.Z
not found in tailscale-operator index.
```

The fix is to update the `version =` line in `modules/services/k3s.nix`,
rebuild, then delete the failed Job as shown above.


When these Jobs succeed you'll see the operator pods themselves:

```sh
kubectl -n openebs   get pods   # zfs-localpv-controller + per-node DaemonSet
kubectl -n tailscale get pods   # operator-... pod
```

If the Tailscale operator pod is `CrashLoopBackOff`, check the pod logs
first — the failure mode dictates the fix:

```sh
kubectl -n tailscale logs deploy/operator --tail=50
```

| Log message contains | Cause | Fix |
|---|---|---|
| `requested tags [tag:k8s] are invalid or not permitted` | OAuth client is missing `tag:k8s` in its per-client allowed-tags list | See [Section 10 → OAuth client scopes](#oauth-client-scopes). Tick `tag:k8s` in the OAuth client UI, regenerate, update sops, `nh os switch`, restart the deploy. |
| `Status: 401` or `invalid client` | Wrong / rotated OAuth client id or secret | Re-mint the OAuth client, update `secrets/chopper/secrets.yaml`, `nh os switch`. |
| `tag:k8s ... not in tagOwners` | `tag:k8s` is not declared in the tailnet ACL | See [Section 10 → Tags / Minimum ACL rules](#10-tailscale-acl-requirements). |
| `NeedsLogin` for more than a few seconds with no further progress | OAuth flow is reaching Tailscale but no auth key is being returned — same root cause as the `tag:k8s` row above | Same fix as the first row. |

Quick checks for the secret pipeline itself:

```sh
kubectl -n tailscale get secret operator-oauth -o yaml
# stringData should be populated, NOT empty.
sudo systemctl status k3s-tailscale-oauth-secret
```


#### From a remote admin machine over Tailscale

To administer the cluster from your laptop or another tailnet member,
copy the kubeconfig and rewrite the `server:` URL to use the node's
Tailscale FQDN (the apiserver's TLS cert already includes
`chopper` as a SAN — see `extraFlags` in `hosts/chopper/parts/k3s.nix`;
add your tailnet FQDN there once known):

```sh
# On the laptop:
mkdir -p ~/.kube
scp chopper:/etc/rancher/k3s/k3s.yaml ~/.kube/chopper.yaml
chmod 0600 ~/.kube/chopper.yaml

# Rewrite the server address. Use the bare hostname if MagicDNS is on,
# or the full FQDN otherwise:
sed -i '' 's|https://127.0.0.1:6443|https://chopper:6443|' \
  ~/.kube/chopper.yaml
# (drop the '' on Linux)

export KUBECONFIG=~/.kube/chopper.yaml
kubectl get nodes
```

If you get a TLS hostname mismatch (`x509: certificate is valid for ...,
not chopper.<tailnet>.ts.net`), add the FQDN to the apiserver's TLS SANs
by uncommenting the second `--tls-san=...` line in
`hosts/chopper/parts/k3s.nix`, rebuild with `nh os switch`, and restart
k3s. The apiserver regenerates its serving cert on next start.

For resilience across node loss (Phase 3+), merge multiple host
kubeconfigs and keep contexts named `chopper`, `node-2`, etc.; switch
with `kctx` (alias for `kubectl config use-context`).


### Drain a node for maintenance

```sh
# Cordon (prevent new pods) and evict existing pods
kubectl drain chopper --ignore-daemonsets --delete-emptydir-data

# Perform maintenance (reboot, k3s upgrade, etc.)
# When ready:
kubectl uncordon chopper
```

Always trigger a CNPG switchover before draining the node hosting the primary:

```sh
kubectl cnpg promote chopper-pg <replica-pod-name> -n cnpg
# Wait for switchover confirmation, then drain
```

---

## 7. Backup and restore

### How backups work

CNPG uses **Barman Cloud** for both continuous WAL archiving and scheduled base
backups. All backup targets are configured in the `ObjectStore` CR.

```
CNPG primary pod
  │
  ├── Continuous WAL archiving (every completed WAL segment, ~16 MB or ~5 min)
  │     └──► Barman Cloud
  │               ├── Garage (local S3 on chopper) — warm copy, fast restore
  │               └── Backblaze B2 / Cloudflare R2 — off-site, disaster recovery
  │
  └── Scheduled base backups (daily, via ScheduledBackup CR)
        └──► same targets
```

**PITR window:** ≥ 7 days. The `ScheduledBackup` retains daily base backups for
7 days; WAL segments fill in the gaps between them.

**RPO with synchronous replication:** ≈ 0. A transaction is not committed to
the primary until at least one synchronous replica has acknowledged receipt.
The primary never gets ahead of the replica by more than one WAL segment at the
moment the primary's node dies.

### Verify backup health

```sh
# List recent backups
kubectl get backup -n cnpg

# Check the last scheduled backup status
kubectl describe scheduledbackup chopper-pg-daily -n cnpg

# Trigger a manual backup immediately
kubectl cnpg backup chopper-pg -n cnpg

# Check Barman status (inside the primary pod)
kubectl exec -it chopper-pg-1 -n cnpg -- \
  barman-cloud-check-wal-archive \
  --cloud-provider aws-s3 \
  --endpoint-url https://s3.garage.chopper.local \
  s3://cnpg-backups chopper-pg
```

### Point-in-time recovery (PITR)

Restoring to a specific timestamp requires creating a new CNPG `Cluster`
pointing at the same `ObjectStore` with a `bootstrap.recovery.recoveryTarget`
block. **Do not restore in-place into the live cluster.**

See the detailed runbook: `k8s/docs/runbooks/restore-pitr.md`

### What happens if both laptops die (worst case)

All local data (ZFS pool) is lost. Off-site backup (B2/R2) is the only copy.
Recovery procedure:

1. Bootstrap a new k3s cluster on fresh hardware.
2. Create the `cnpg-backup-s3-creds` Secret manually (from the master age key
   and the sops-encrypted file in git).
3. Deploy the CNPG operator.
4. Create a new `Cluster` CR with `bootstrap.recovery` pointing at the B2/R2
   `ObjectStore`, with `recoveryTarget.targetTime` set to the desired recovery
   point.
5. CNPG downloads the latest base backup and replays WAL segments up to the
   target time.

This procedure is time-consuming (proportional to database size + WAL replay
window). Document your expected RTO and test it annually.

---

## 8. Adding a node

See the detailed runbook: `k8s/docs/runbooks/add-node.md`

### Summary

1. Provision the new machine as a NixOS host with `profiles/k3s-node.nix`.
2. Set `metadata.roles = [ "k3s" ]` and `services.k3s-cluster.role`.
3. sops-encrypt `secrets/<newhost>/k3s-token` for the new host's age key
   (or re-encrypt the existing one to include the new host's key if you want
   to share the same file — the `path_regex` in `.sops.yaml` must match).
4. Deploy: `nh os switch -- --target-host <newhost>`.
5. Verify: `kubectl get nodes` should show the new node as `Ready`.

### Flip CNPG pod anti-affinity

When moving from Phase 1 (1 node) to Phase 3 (3 nodes), update the CNPG
`Cluster` CR:

```yaml
# k8s/clusters/chopper/cnpg-cluster.yaml
spec:
  instances: 3
  affinity:
    podAntiAffinityType: required   # change from "preferred" to "required"
    topologyKey: kubernetes.io/hostname
```

Apply via `just k8s-apply`. CNPG will roll the instances one at a time onto
separate nodes. No downtime if PgBouncer is in front.

---

## 9. Monitoring and alerting

### Recommended stack

`kube-prometheus-stack` (Prometheus + Alertmanager + Grafana) deployed from
`k8s/apps/kube-prometheus-stack/`. CNPG ships built-in `PodMonitor` and
`PrometheusRule` objects — enable them in `cnpg-cluster.yaml`:

```yaml
spec:
  monitoring:
    enablePodMonitor: true
```

### Critical alerts to configure

| Alert | Why it matters |
|---|---|
| `CNPGReplicationLagHigh` (lag > 30s) | Sync replica is falling behind; a node loss could lose transactions |
| `CNPGPrimaryNotAvailable` | Primary pod is gone; CNPG is promoting (or stuck) |
| `CNPGBackupFailed` | Last backup did not complete; PITR window is at risk |
| `CNPGWALArchivingFailing` | WAL segments are piling up on the primary; disk pressure |
| `EtcdMemberNotHealthy` | etcd quorum is degraded; cluster is at risk |
| `KubeNodeNotReady` | A k3s node is unreachable |
| `PersistentVolumeFillingUp` | ZFS LocalPV PVC is near capacity |

### What to watch in k9s

```sh
k9s
# Navigate to: :pods -n cnpg
# Watch for: primary/replica labels, restart counts, resource usage
#
# Check PVCs:  :pvc -n cnpg
# Check nodes: :nodes
# Check events: :events -n cnpg
```

CNPG labels pods with `role=primary` and `role=replica` so you can quickly
identify the current primary at a glance.

### Grafana dashboards

CNPG provides pre-built Grafana dashboards. Import dashboard ID `20417`
(CloudNativePG) from grafana.com into your kube-prometheus-stack Grafana
instance.

---

## 10. Tailscale ACL requirements

The cluster relies on several Tailscale ACL configurations. These must be set
in the Tailscale admin console at `https://login.tailscale.com/admin/acls`.

### Tags

| Tag | Used by | Purpose |
|---|---|---|
| `tag:k8s` | Tailscale operator | All devices managed by the Tailscale k8s operator get this tag. The OAuth client must be authorised to create auth keys for this tag. |
| `tag:k8s-operator` | Tailscale operator pod itself | The operator's own device identity. |
| `tag:server` | chopper (and future nodes) | k3s nodes. Used in ACL rules to allow other tagged devices to reach the PostgreSQL port. |

### Minimum ACL rules

```json
{
  "tagOwners": {
    "tag:k8s":          ["autogroup:admin"],
    "tag:k8s-operator": ["autogroup:admin"],
    "tag:server":       ["autogroup:admin"]
  },
  "acls": [
    {
      // Cloud webservices → PostgreSQL (via Tailscale operator proxy)
      "action": "accept",
      "src":    ["autogroup:member", "tag:k8s"],
      "dst":    ["tag:k8s:5432"]
    },
    {
      // k3s inter-node traffic (apiserver, etcd peers, kubelet, flannel)
      // All traffic stays on tailscale0; WireGuard provides encryption.
      "action": "accept",
      "src":    ["tag:server"],
      "dst":    ["tag:server:*"]
    },
    {
      // Laptop admin access (kubectl, SSH, nh deploys)
      "action": "accept",
      "src":    ["autogroup:admin"],
      "dst":    ["tag:server:*"]
    }
  ]
}
```

### OAuth client scopes

The OAuth client created for `secrets/chopper/tailscale-operator-oauth` must
have **all three** of the following set in the Tailscale admin UI at
`https://login.tailscale.com/admin/settings/oauth`:

- **Scope:** `devices` → *Write* (to register new proxy devices)
- **Scope:** `auth_keys` → *Write* (to create ephemeral auth keys for pods)
- **Tags:** **`tag:k8s` MUST be ticked in the "Tags" section of the
  OAuth client form.**

The third bullet is the most common gotcha. Declaring `tag:k8s` in
`tagOwners` of the ACL is necessary but **not sufficient** — each OAuth
client additionally has its own per-client allow-list of tags it may mint
auth keys for. If `tag:k8s` is not ticked there, the operator pod logs
(`kubectl -n tailscale logs deploy/operator`) will contain:

```
fatal	creating operator authkey:
Status: 400, Message: "requested tags [tag:k8s] are invalid or not permitted"
```

Fix: edit the OAuth client, tick `tag:k8s` (and `tag:k8s-operator` if you
use it for the operator's own identity), regenerate the client secret if
the UI forces you to, then update the sops-encrypted file:

```sh
sops secrets/chopper/secrets.yaml
# update tailscale-operator-client-id / tailscale-operator-client-secret,
# then save & exit — the editor re-encrypts in place.

nh os switch                                  # re-deploys the Secret manifest
kubectl -n tailscale rollout restart deploy/operator
kubectl -n tailscale logs -f deploy/operator
```

Without these scopes the Tailscale operator cannot register the `pg-rw`
proxy device and the stable PostgreSQL endpoint will not come up.


### MagicDNS

MagicDNS must be **enabled** in the Tailscale admin console. The stable
hostname `pg-rw.<tailnet>.ts.net` is the MagicDNS record created by the
Tailscale operator for the LoadBalancer Service. If MagicDNS is disabled,
cloud webservices must use the raw Tailscale IP instead — which changes on
every re-registration.

### Split DNS (optional but recommended)

Configure split DNS in Tailscale admin to resolve `<tailnet>.ts.net` names
only for tailnet-connected clients. This prevents accidental leakage of
internal DNS names to public resolvers.

---

## Appendix — Repository layout

```
k8s/
├── helmfile.yaml                      # pins CNPG operator + future charts
├── apps/
│   ├── cnpg-operator/
│   │   ├── values.yaml
│   │   └── secrets.yaml               # sops-encrypted Helm secrets
│   └── kube-prometheus-stack/
│       └── values.yaml
├── clusters/
│   └── chopper/
│       ├── kustomization.yaml
│       ├── cnpg-cluster.yaml          # Cluster CR (instances, storage, affinity)
│       ├── cnpg-pooler.yaml           # Pooler CR (PgBouncer in front of -rw)
│       ├── cnpg-backup.yaml           # ScheduledBackup + ObjectStore CRs
│       ├── tailscale-pg-service.yaml  # tailscale LoadBalancer for the pooler
│       └── secrets/
│           └── cnpg-backup-s3.enc.yaml  # sops-encrypted Secret manifest
└── docs/
    └── runbooks/
        ├── add-node.md
        ├── failover.md
        └── restore-pitr.md

modules/services/k3s.nix              # NixOS module (k3s + bootstrap charts)
profiles/k3s-node.nix                 # role — add "k3s" to metadata.roles
secrets/chopper/k3s-token             # sops Tier-1 (k3s join token)
secrets/chopper/tailscale-operator-oauth  # sops Tier-1 (OAuth creds)
docs/k3s-cnpg.md                      # this file
```

---

*Last updated: see git log. For questions, see the architecture decisions in
`CLAUDE.md` § 7 and the milestone plan in `ROADMAP.md`.*
