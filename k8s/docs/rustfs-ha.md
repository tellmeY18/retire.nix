# RustFS High Availability Architecture

This document describes the target HA architecture for RustFS (S3-compatible
object storage) across the glug-infra k3s cluster.

## Goal

**If any single node goes down, S3 service continues uninterrupted for both
reads AND writes.** No manual intervention required.

## Current State (interim, single-node)

- Pool-0: 4 servers × 2 volumes = 8 drives, all on `chopper`
- Erasure set: 8 drives, EC:4 (default parity)
- Tolerates: up to 4 drive/pod failures on the same node
- **Does NOT survive chopper going down** — single point of failure

## The Math: Why Multi-Pool Doesn't Give HA

The previous attempt (pool-0 on chopper + pool-1 on c3po) **failed** because:

1. **Multi-pool ≠ replication.** Each pool is an independent erasure set.
   Objects placed on pool-1 are ONLY on pool-1 — if that pool is down, those
   objects are unavailable.
2. **Worse:** if any pool endpoint is unreachable, RustFS returns 500 for ALL
   requests (including data that lives entirely on the healthy pool).
3. Pools are for **capacity expansion**, not redundancy.

## The Correct Architecture: Single Pool Spanning 3 Nodes

For true HA, we need a **single erasure set distributed across multiple nodes**
with sufficient parity to survive the loss of any one node's worth of drives.

### Erasure Coding Quorum Rules

For an erasure set of N drives with parity P:
- **Read quorum:** N − P drives must be alive
- **Write quorum:** N − P + 1 drives must be alive
- **Maximum parity:** N/2

### Why 2 Nodes Can Never Give Write HA

With 2 symmetric nodes (each holding N/2 drives):
- Maximum parity = N/2
- Write quorum = N − N/2 + 1 = **N/2 + 1**
- Drives surviving one node loss = **N/2**
- N/2 < N/2 + 1 → **writes always fail** when a node is down

This is a mathematical impossibility, not a configuration issue.

### 3-Node Solution

With 3 nodes each contributing N/3 drives:
- Parity = N/2 (maximum)
- Write quorum = N/2 + 1
- Drives surviving one node loss = 2N/3
- Need: 2N/3 ≥ N/2 + 1 → satisfied for N ≥ 6

**Minimum viable: 6 drives (2 per node), parity 3.**
- Read: need 3 drives → survives losing any node (4 remain) ✓
- Write: need 4 drives → survives losing any node (4 remain) ✓

## Target Configuration

```
┌─────────────────────────────────────────────────────────┐
│                  Single Erasure Set (12 drives)          │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   chopper    │  │    c3po     │  │   kenobi    │    │
│  │  (primary)   │  │  (support)  │  │  (support)  │    │
│  │             │  │             │  │             │    │
│  │  server-0   │  │  server-4   │  │  server-8   │    │
│  │   vol0,vol1 │  │   vol0,vol1 │  │   vol0,vol1 │    │
│  │  server-1   │  │  server-5   │  │  server-9   │    │
│  │   vol0,vol1 │  │   vol0,vol1 │  │   vol0,vol1 │    │
│  │  server-2   │  │  server-6   │  │  server-10  │    │
│  │   vol0,vol1 │  │   vol0,vol1 │  │   vol0,vol1 │    │
│  │  server-3   │  │  server-7   │  │  server-11  │    │
│  │   vol0,vol1 │  │   vol0,vol1 │  │   vol0,vol1 │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Drives per node: 8      4 drives       4 drives       │
│  Total: 12 servers × 2 volumes = 24 drives (*)         │
└─────────────────────────────────────────────────────────┘
```

**(*) IMPORTANT: For symmetric HA, each node must contribute EQUAL drives.**

### Recommended: 4 servers per node × 2 volumes = 8 drives/node

| Parameter | Value |
|-----------|-------|
| Nodes | 3 (chopper, c3po, kenobi) |
| Servers per node | 4 |
| Volumes per server | 2 |
| Total drives | 24 |
| Erasure set size | 8 (24 ÷ 3 sets) |
| Parity per set | 4 (default, maximum for set size 8) |
| Read quorum per set | 4 drives |
| Write quorum per set | 5 drives |
| Drives per node per set | ~2-3 (distributed by RustFS) |
| **Node failure tolerance** | **Any 1 node** (read ✓, write ✓) |

With 24 drives and erasure set size 8, RustFS creates 3 independent erasure
sets. It distributes drives across nodes within each set for maximum
resilience. Losing one node (8 drives) means each set loses ~2-3 drives,
leaving 5-6 drives per set — above both read (4) and write (5) quorum.

### Alternative: 2 servers per node (lighter, still HA)

| Parameter | Value |
|-----------|-------|
| Nodes | 3 |
| Servers per node | 2 |
| Volumes per server | 2 |
| Total drives | 12 |
| Erasure set size | 12 (single set) |
| Parity | 6 (maximum) |
| Read quorum | 6 drives |
| Write quorum | 7 drives |
| Drives per node | 4 |
| **Node failure tolerance** | **Any 1 node** (8 remain → read ✓, write ✓) |

This uses fewer pods (6 vs 12) but gives the same HA guarantee. The trade-off
is less parallelism and ~600 GiB raw (300 GiB usable at EC:6) vs 1.2 TiB raw
(600 GiB usable at EC:4).

## Migration Plan

### Prerequisites

1. All 3 nodes (chopper, c3po, kenobi) must be `Ready`
2. Each node needs the `zfs-localpv` StorageClass available
3. Back up all existing data (`mc mirror` to an off-site bucket)

### Steps

1. **Back up existing data:**
   ```sh
   mc alias set rustfs http://rustfs-storage-io.rustfs-clusters.svc:9000 <access> <secret>
   mc mirror rustfs/ghost backup/ghost-$(date +%Y%m%d)
   ```

2. **Create new tenant** (cannot resize erasure sets in-place):
   - Deploy a new Tenant CR (`rustfs-storage-v2`) with the 3-node config
   - Wait for all pods to be Ready and the tenant to report `Ready`

3. **Migrate data:**
   ```sh
   mc mirror rustfs-old/ghost rustfs-new/ghost --preserve --overwrite
   ```

4. **Switch Ghost to new endpoint:**
   - Update `storage__s3__endpoint` to the new tenant's IO service
   - Rolling restart Ghost

5. **Decommission old tenant:**
   - Delete old tenant CR
   - Clean up PVCs

### Tenant CR (target)

```yaml
apiVersion: rustfs.com/v1alpha1
kind: Tenant
metadata:
  name: rustfs-storage
  namespace: rustfs-clusters
spec:
  image: rustfs/rustfs:latest
  credsSecret:
    name: rustfs-credentials
  podManagementPolicy: Parallel
  pools:
    - name: pool-0
      servers: 12   # 4 per node × 3 nodes
      persistence:
        volumesPerServer: 2
        volumeClaimTemplate:
          accessModes: ["ReadWriteOnce"]
          storageClassName: zfs-localpv
          resources:
            requests:
              storage: 50Gi
      # Ensure even distribution: exactly 4 pods per node
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              rustfs.pool: pool-0
      resources:
        requests:
          cpu: "200m"
          memory: "512Mi"
        limits:
          cpu: "1000m"
          memory: "2Gi"
  env:
    - name: RUST_LOG
      value: info
    - name: RUSTFS_DOMAIN
      value: s3.internal
    # Set maximum parity for best HA
    - name: RUSTFS_STORAGE_CLASS_STANDARD
      value: "EC:4"
```

## Failure Scenarios

| Scenario | Impact | Recovery |
|----------|--------|----------|
| 1 pod dies | Zero — erasure handles it | k8s reschedules automatically |
| 1 node down | Zero — quorum maintained | Automatic when node returns |
| 2 nodes down | **Service unavailable** | Need 2/3 nodes back |
| 1 drive (PVC) corrupt | Zero | RustFS self-heals from parity |
| All 3 nodes down | **Total outage** | Restore from off-site backup |

## Monitoring

The existing RustFS VMRules and Grafana dashboard (`rustfs-vmrules.yaml`,
`rustfs-grafana-dashboard.yaml`) are node-agnostic and will automatically
monitor the new architecture without changes.

Add these alerts for the HA setup:
- `RustFSNodeMissing` (warning): fewer than 3 nodes have running RustFS pods
- `RustFSWriteQuorumAtRisk` (critical): only 1 node has running pods (next
  failure = write unavailability)

## What We Are NOT Doing

- **Site Replication** — overkill for 3 nodes in a single cluster
- **Multiple pools** — proven to cause total outage when a pool is unreachable
- **Longhorn/Ceph underneath** — RustFS IS the distributed storage layer
- **Public internet exposure for writes** — S3 writes only from within the
  tailnet; public reads via Tailscale Funnel are read-only
