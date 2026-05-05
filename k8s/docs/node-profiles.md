# Node Profiles & Scheduling Architecture

This cluster uses two node profiles to separate **storage** (on-prem laptops)
from **compute** (ephemeral cloud VMs). The core invariant:

> **PVCs are NEVER provisioned on compute nodes. All persistent state lives on
> storage nodes. Stateless pods float freely across all nodes.**

---

## Node Roles

| Role | Profile | Hardware | Labels | Taint |
|------|---------|----------|--------|-------|
| **Storage** | `k3s-storage-node.nix` | On-prem laptops with ZFS | `node-role.glug.infra/storage=true` | `PreferNoSchedule` (pushes stateless pods away) |
| **Compute** | `k3s-compute-node.nix` | Cloud VMs (spot/preemptible) | `node-role.glug.infra/compute=true` | None (eagerly attracts all stateless pods) |

---

## How PVCs stay on storage nodes (3 layers of enforcement)

1. **StorageClass `allowedTopologies`** — Both `zfs-localpv` and `zfs-localpv-16k`
   StorageClasses have topology constraints requiring `node-role.glug.infra/storage=true`.
   The CSI provisioner will REFUSE to create a PV on any node without this label.

2. **`volumeBindingMode: WaitForFirstConsumer`** — The PVC doesn't bind until the
   pod is scheduled. The scheduler sees that only storage nodes satisfy the topology
   constraint and places the pod there.

3. **No ZFS on compute nodes** — Even without the above, OpenEBS ZFS LocalPV
   physically can't provision on a node without a ZFS pool. Belt + suspenders + parachute.

---

## How stateless pods prefer compute nodes

The scheduling preference is driven by a single mechanism:

- **Storage nodes** have a soft taint: `PreferNoSchedule`
- **Compute nodes** have NO taint

The scheduler sees two choices for a stateless pod:
- Compute node: "no taints, welcome!" → **preferred**
- Storage node: "PreferNoSchedule, try elsewhere first" → **avoided**

This means:
- When compute nodes are UP → stateless pods land there (storage stays lean)
- When compute nodes go DOWN → pods reschedule to storage (soft, not refused)
- No tolerations needed on any Deployment — `PreferNoSchedule` is advisory

### Graceful degradation when compute nodes die

```
Normal state (compute UP):              Degraded state (compute DOWN):

┌───────────────────┐                     ┌───────────────────┐
│ storage (chopper)   │                     │ storage (chopper)   │
│                     │                     │                     │
│  postgres ×3   ~260M │                     │  postgres ×3   ~260M │
│  mysql pxc    ~610M │                     │  mysql pxc    ~610M │
│  vmsingle     ~290M │                     │  vmsingle     ~290M │
│  daemonsets    ~60M │                     │  daemonsets    ~60M │
│                     │                     │  grafana      ~230M │
│  (that's it!)       │                     │  vmagent       ~90M │
│  FREE: ~3 GB        │                     │  operators    ~250M │
└───────────────────┘                     │  proxies      ~170M │
                                            │  etc...             │
┌───────────────────┐                     │  FREE: ~1.9 GB      │
│ compute (cloud VM)  │                     └───────────────────┘
│                     │
│  grafana      ~230M │                     ┌───────────────────┐
│  vmagent       ~90M │                     │ compute (cloud VM)  │
│  operators    ~250M │                     │                     │
│  proxies      ~170M │                     │  ❌ OFFLINE          │
│  ts-proxies   ~240M │                     │                     │
│  web apps     ~xxxM │                     └───────────────────┘
│                     │
│  FREE: plenty        │
└───────────────────┘
```

The cluster never refuses to run workloads — it just prefers the right place.
When compute returns, the scheduler gradually migrates pods back (on next
reschedule/restart).

---

## What runs where

| Workload | Runs on storage? | Runs on compute? | Why |
|----------|:---:|:---:|-----|
| CNPG Postgres instances | ✅ | ❌ | Needs PVC (ZFS) |
| PXC MySQL instances | ✅ | ❌ | Needs PVC (ZFS) |
| VMSingle (metrics TSDB) | ✅ | ❌ | Needs PVC (ZFS) |
| PgBouncer pooler | ✅ | ✅ | Stateless |
| HAProxy (PXC) | ✅ | ✅ | Stateless |
| VMAgent (scraper) | ✅ | ✅ | Stateless |
| VMAlert (rule eval) | ✅ | ✅ | Stateless |
| Grafana | ✅ | ✅ | Stateless (no persistence) |
| node-exporter | ✅ | ✅ | DaemonSet (runs everywhere) |
| kube-state-metrics | ✅ | ✅ | Stateless |
| Custom web apps | ✅ | ✅ | Stateless |
| Batch/CI jobs | ✅ | ✅ | Stateless |

---

## Database ecosystem: what's stateful vs stateless

A "database" in Kubernetes is not a single pod — it's an ecosystem of
components. Only the actual data-engine pod needs a PVC. Everything else
in the database stack is stateless and can run on compute nodes:

### CNPG (PostgreSQL) components

| Component | What it does | Needs PVC? | Runs on compute? |
|---|---|:---:|:---:|
| `postgres-cluster-1/2/3` | The actual PostgreSQL process. Reads/writes data files. | ✅ | ❌ Never |
| **CNPG operator** | Control-plane: watches Cluster CRs, triggers failovers, manages backups. Doesn't touch data files. | ❌ | ✅ |
| **PgBouncer** (Pooler) | TCP connection multiplexer. Holds no data — just forwards SQL packets between clients and the primary. | ❌ | ✅ |

### PXC (MySQL) components

| Component | What it does | Needs PVC? | Runs on compute? |
|---|---|:---:|:---:|
| `mysql-pxc-db-pxc-0` | The actual MySQL/Galera process. Reads/writes InnoDB files. | ✅ | ❌ Never |
| **PXC operator** | Control-plane: watches PerconaXtraDBCluster CRs, manages rolling updates, orchestrates backups. | ❌ | ✅ |
| **HAProxy** | TCP router. Health-checks PXC nodes and forwards connections to the current Galera writer. | ❌ | ✅ |
| **mysqld-exporter** sidecar | Scrapes MySQL metrics. Runs as a sidecar inside the PXC pod (so it goes wherever the PXC pod goes). | ❌ (shares PXC pod) | ❌ (tied to PXC pod) |

### VictoriaMetrics (monitoring) components

| Component | What it does | Needs PVC? | Runs on compute? |
|---|---|:---:|:---:|
| **VMSingle** | Time-series database. Stores all scraped metrics on disk. | ✅ | ❌ Never |
| **VM operator** | Control-plane: watches VMAgent/VMAlert/VMRule CRs. | ❌ | ✅ |
| **VMAgent** | Scrapes metrics from targets, pushes to VMSingle over HTTP. | ❌ | ✅ |
| **VMAlert** | Evaluates alerting/recording rules by querying VMSingle. | ❌ | ✅ |
| **VMAlertmanager** | Routes fired alerts to receivers (Slack, email, etc). | ❌ | ✅ |
| **Grafana** | Dashboard UI. Queries VMSingle over HTTP. | ❌ | ✅ |

### Key insight

> **Operators are just Kubernetes controllers** — they watch the API server
> for CR changes and reconcile state. They never touch data files directly.
> They are fully stateless Deployments that can run anywhere, restart
> instantly, and lose nothing if their node disappears.

The same applies to proxies (PgBouncer, HAProxy) — they're dumb TCP pipes.
They maintain no on-disk state. Kill them, reschedule them on a different
node, and clients reconnect transparently.

The ONLY components that are physically bound to storage nodes are the
**data-engine pods** — the ones that `mount` a PVC and do `read()`/`write()`
system calls against database files on the local ZFS dataset.

---

## Adding a new storage node (laptop)

```nix
# hosts/new-laptop/default.nix
{
  imports = [
    ../../profiles/k3s-storage-node.nix
    ../../profiles/zfs.nix
  ];

  services.k3s-cluster = {
    enable     = true;
    role       = "server";        # joins existing cluster
    serverAddr = "https://chopper:6443";
    tokenFile  = config.sops.secrets.k3s-token.path;
    nodeIP     = "100.x.y.z";    # tailscale IP
  };
}
```

Prerequisites on the new laptop:
1. ZFS pool with `rpool/openebs` dataset
2. Tailscale connected to the same tailnet
3. k3s token in sops secrets

---

## Adding a new compute node (cloud VM)

```nix
# hosts/cloud-vm-01/default.nix
{
  imports = [
    ../../profiles/k3s-compute-node.nix
  ];

  services.k3s-cluster = {
    enable     = true;
    role       = "agent";         # worker only, no control plane
    serverAddr = "https://chopper:6443";
    tokenFile  = config.sops.secrets.k3s-token.path;
    nodeIP     = "100.x.y.z";    # tailscale IP
  };
}
```

No ZFS, no storage setup needed. Just tailscale + k3s token.

---

## Scaling considerations

| Nodes | Etcd quorum | Storage HA | Compute HA |
|-------|:-----------:|:----------:|:----------:|
| 1 storage | ❌ | ❌ | N/A |
| 2 storage | ❌ (even=bad) | Replicas spread | N/A |
| 3 storage | ✅ | Full HA | N/A |
| 3 storage + N compute | ✅ | Full HA | ✅ |

When you reach 3 storage nodes:
- Bump `pxc.size: 3` and `haproxy.size: 2` in `apps/mysql/values.yaml`
- Remove `unsafeFlags` from PXC config
- CNPG can set `instances: 3` with `requiredDuringScheduling` anti-affinity
- Etcd quorum survives any single node failure

---

## PVC & Storage Deep Dive — How Data Actually Works

This section explains the physical reality of storage in this cluster. If you're
coming from traditional servers where "the database just uses a disk", the k8s
storage model has a key difference: **storage is node-local and non-portable.**

### What is a PVC?

A PVC (PersistentVolumeClaim) is a pod's request for disk space. Think of it as:

```
PVC = "I need 20GB of storage"
 PV = "Here's an actual ZFS dataset on chopper's SSD that satisfies that request"
```

The PVC is the abstract request; the PV (PersistentVolume) is the real disk.
In our setup, PVs are **ZFS datasets** carved out of `rpool/openebs` on a
specific laptop's physical NVMe drive.

### PVCs are LOCAL — not network storage

**This is the single most important thing to understand:**

> OpenEBS ZFS LocalPV creates a ZFS dataset on ONE node's physical disk.
> That data exists ONLY on that node. It is NOT replicated, NOT network-
> accessible, NOT shared. It's just a directory on one machine's SSD.

Consequence: **a pod that uses a PVC MUST run on the same physical node as
the PVC.** The pod can't be on `chopper` while its data is on `laptop-2`.
Kubernetes enforces this automatically — if a pod's PVC lives on `chopper`,
the scheduler will ONLY place that pod on `chopper`.

```
┌─────────────────────────────────────────────────────────────────┐
│ chopper (storage node)                                          │
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────────────────────┐   │
│  │ postgres-pod-1  │────▶│ PVC: /rpool/openebs/pvc-abc123  │   │
│  │ (CNPG instance) │     │ (ZFS dataset, 20GB, on THIS SSD)│   │
│  └─────────────────┘     └─────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────────────────────┐   │
│  │ mysql-pxc-pod-0 │────▶│ PVC: /rpool/openebs/pvc-def456  │   │
│  │ (PXC instance)  │     │ (ZFS dataset, 20GB, on THIS SSD)│   │
│  └─────────────────┘     └─────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ cloud-vm-01 (compute node)                                      │
│                                                                 │
│  ┌─────────────────┐                                            │
│  │ pgbouncer-pod   │──── TCP:5432 ───▶ postgres-pod-1           │
│  │ (stateless)     │     (network)      (on chopper)            │
│  └─────────────────┘                                            │
│                                                                 │
│  ┌─────────────────┐                                            │
│  │ my-web-app      │──── TCP:5432 ───▶ pgbouncer-pod            │
│  │ (stateless)     │     (network)      (same node or remote)   │
│  └─────────────────┘                                            │
│                                                                 │
│  ❌ NO PVCs here. No ZFS. No persistent disk.                   │
└─────────────────────────────────────────────────────────────────┘
```

### Can a pod on a compute node access a PVC on a storage node?

**No. Absolutely not. A PVC is not network storage.**

A PVC backed by OpenEBS ZFS LocalPV is a raw ZFS dataset mount. It's like
a directory on `/dev/nvme0n1`. There is no NFS, no iSCSI, no network protocol
exposing it. A pod on `cloud-vm-01` cannot mount a ZFS dataset that physically
exists on `chopper`'s SSD — the bits are not accessible over the network.

That's why database pods (Postgres, MySQL) are **pinned to storage nodes**.
They need to read/write their data files directly, and those files only exist
on the local disk.

### Can multiple pods share a PVC?

It depends on the access mode:

| Access Mode | Meaning | Our setup |
|---|---|---|
| `ReadWriteOnce` (RWO) | One node can mount it read-write | ✅ Default. Multiple pods on the SAME node can share it. |
| `ReadWriteMany` (RWX) | Multiple nodes can mount it | ❌ NOT supported by LocalPV. Would need NFS/Ceph. |
| `ReadOnlyMany` (ROX) | Multiple nodes can mount it read-only | ❌ Not used. |

Our StorageClass provides **RWO only**. Even if two pods on the same node
try to mount the same PVC, databases don't do this — each database instance
gets its own dedicated PVC because databases use exclusive file locks.

### Then how do databases replicate across nodes?

**They replicate at the APPLICATION layer, not the storage layer.**

Each database instance has its OWN PVC on its OWN node. Data is copied
between instances using the database's built-in replication protocol:

```
┌───────── laptop-1 ─────────┐     ┌───────── laptop-2 ─────────┐
│                             │     │                             │
│  postgres-1 (primary)       │     │  postgres-2 (replica)       │
│  PVC-A (20GB, local ZFS)    │     │  PVC-B (20GB, local ZFS)    │
│         │                   │     │         ▲                   │
│         └───── WAL stream (TCP) ──┘         │                   │
│               (Postgres streaming           │                   │
│                replication)                  │                   │
└─────────────────────────────┘     └─────────────────────────────┘
```

- **CNPG (Postgres):** Uses PostgreSQL streaming replication. The primary
  ships WAL (Write-Ahead Log) segments over TCP to replicas. Each instance
  has its own PVC. If the primary dies, a replica is promoted — it already
  has a full copy of the data on its own local PVC.

- **PXC (MySQL):** Uses Galera synchronous replication (wsrep). Every write
  is certified and applied to ALL nodes simultaneously via TCP. Each PXC
  node has its own PVC. If one node dies, the others have the same data.

Key insight: **the network carries SQL replication traffic, NOT raw disk I/O.**
This is far more efficient and reliable than trying to share a filesystem
over the network.

### How do apps on compute nodes talk to databases?

Through the **network** (TCP), via a Service or proxy:

```
web-app (on cloud-vm)                     (the Kubernetes Service abstracts
    │                                      away which node the DB is on)
    │ TCP:5432
    ▼
k8s Service: postgres-cluster-rw          (ClusterIP, routes to primary)
    │
    ▼
PgBouncer pod (on ANY node)               (connection pooler, stateless)
    │
    │ TCP:5432
    ▼
postgres-cluster-1 (on chopper)           (the actual DB with PVC)
```

The web app doesn't know or care where the database physically lives. It
connects to a Kubernetes Service name (`postgres-cluster-rw`) which resolves
to whatever node currently hosts the primary. The flannel overlay network
(encrypted via Tailscale) carries the traffic between nodes transparently.

### Summary: who accesses what

| Actor | Accesses PVC directly? | Accesses DB over network? |
|-------|:---:|:---:|
| Database pod (CNPG/PXC) | ✅ Local disk mount | N/A (it IS the DB) |
| Another DB replica | ❌ Has its OWN PVC | ✅ Replication stream |
| PgBouncer / HAProxy | ❌ No PVC at all | ✅ TCP proxy to DB |
| Web app on compute node | ❌ No PVC at all | ✅ TCP via Service |
| Web app on storage node | ❌ (unless it has its own PVC) | ✅ TCP via Service |
| VMSingle (metrics DB) | ✅ Local PVC for TSDB data | N/A |
| VMAgent (scraper) | ❌ No PVC | ✅ Writes to VMSingle over HTTP |
| Grafana | ❌ No PVC | ✅ Queries VMSingle over HTTP |

### What if a storage node dies?

- **With 1 storage node (today):** Everything is down. Databases are
  inaccessible until the laptop comes back. Off-site S3 backups are your
  only DR path. Compute nodes can't help — they have no data.

- **With 2+ storage nodes:** CNPG promotes a replica on another laptop.
  PXC Galera continues on surviving nodes. The dead laptop's PVCs are
  orphaned but irrelevant — the promoted replica already has the data.
  New PVCs are created on surviving storage nodes if needed.

- **Compute nodes during storage outage:** Stateless pods keep running
  but can't reach the database. They'll get connection errors until a
  storage node recovers or a replica is promoted.

### Why not use network storage (NFS/Ceph/Longhorn) instead?

| Approach | Pros | Cons | Our verdict |
|---|---|---|---|
| **LocalPV (our choice)** | Fastest I/O, simplest, ZFS features (snapshots, compression) | Pod pinned to node, manual replication | ✅ Best for homelab |
| **Longhorn** | Replicated block storage, pods can move between nodes | 2-3x write amplification, uses network bandwidth, complex | ❌ Overkill, slow on old laptops |
| **NFS** | Simple sharing, any pod anywhere | Single point of failure, terrible for databases (no fsync guarantees) | ❌ Dangerous for DBs |
| **Ceph** | Enterprise distributed storage | Minimum 3 nodes, massive resource overhead, complex ops | ❌ Absurd for 2-3 laptops |

Our approach: **LocalPV for speed + application-layer replication for HA.**
This is what CNPG and PXC are designed for. The database handles replication
better than any block-level solution because it understands the data semantics
(WAL shipping, Galera certification).
