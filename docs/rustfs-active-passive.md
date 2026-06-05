# RustFS: migrate from erasure-coding to active-passive replication

Status: **PLANNED** (to be executed in a dedicated session). Captures the
design + runbook agreed during the 2026-06-05 incident recovery.

---

## 1. Why migrate

Today RustFS runs as a **single distributed erasure-coded set** — 4 pods ×
2 drives = 8 drives, spread across the two storage nodes (`c3po`, `chopper`)
via `tenant-ha.yaml`. In this topology erasure coding is **net-negative**:

- The "drives" are pods on residential laptops that **flap together**
  (network / kubelet / power). A single node blip doesn't drop one
  independent drive — it drops a correlated chunk of the set at once.
- So instead of *tolerating* failures, EC **couples availability to a quorum
  that keeps breaking**: one `c3po` blip → set drops below quorum →
  `store init failed to load formats: erasure read quorum` crashloop →
  `Service not ready` → IAM never initialises → **mediawiki / attic / penpot
  all fail** (this is the exact cascade seen on 2026-06-05).
- **Write amplification + latency**: every write is sharded (data+parity)
  across all drives, so each write waits on `c3po`'s ~360 KB/s residential
  uplink — the original "slow attic→RustFS uploads" complaint.
- **Heal storms** after a node returns keep the store degraded for a long
  time.

The failure model EC assumes (independent, rare drive failures on stable
hardware) does not match correlated node flapping on residential laptops.

**Durability already lives at the right layers** — Postgres replicates via
CNPG, MySQL via MGR, and DR is ZFS snapshots + off-site backups. The object
store does **not** need to be independently HA; it needs to be **simple and
available**.

---

## 2. Target architecture — active-passive, full copies

```
                        apps (mediawiki, attic, penpot, CI)
                          point at ONE stable S3 endpoint
                                      │
                          ┌───────────▼────────────┐
                          │  S3 failover proxy      │  nginx on kenobi
                          │  upstream:              │  (stateless, 2 replicas,
                          │    chopper   (primary)  │   NOT a storage node)
                          │    c3po      (backup)   │
                          └─────┬───────────────┬───┘
              primary    ┌──────▼──────┐   ┌────▼───────┐   warm replica
              (writable) │  rustfs-    │   │  rustfs-   │   (async, may lag)
                         │  chopper    │   │  c3po      │
                         │  STANDALONE │   │  STANDALONE│
                         └──────┬──────┘   └────▲───────┘
                                │  mc mirror --watch (async)
                                └──────────────►┘
                         each = a COMPLETE, independent S3 store
                         on its node's ZFS-backed PVC (no erasure set)
```

Meets the three requirements:

| Requirement | How |
|---|---|
| Both nodes keep a full copy | `mc mirror --watch` replicates every object |
| One node may lag behind | mirror is **asynchronous** |
| One node down → the other stays up | nginx fails over to the surviving store |

This is the object-store equivalent of what was done for CNPG/MySQL during
the incident: stop forcing fragile quorum; use plain replication + failover.

### Why this is safe (no write conflicts)

Objects here are effectively **immutable / unique-keyed**:
- attic NARs are **content-addressed** (the key *is* the hash).
- MediaWiki uploads and Penpot assets use **unique keys**.

So async / last-writer-wins replication has no real conflicts. (If a future
workload does in-place overwrites of the same key from both sides, revisit.)

---

## 3. Components to build

### 3.1 Two standalone RustFS deployments

Replace the single `tenant-ha.yaml` (8-drive EC set) with **two independent
single-node tenants**, each pinned to one storage node:

- `rustfs-chopper` — `nodeSelector kubernetes.io/hostname=chopper`, **one**
  ZFS-backed PVC (`zfs-localpv`), standalone (no erasure / single drive).
- `rustfs-c3po` — `nodeSelector kubernetes.io/hostname=c3po`, same shape.

Key points:
- Standalone mode = `RUSTFS_VOLUMES` points at a **single** local path (not
  the `{0...3}` set), so there is no cross-node quorum and no `erasure read
  quorum` startup gate.
- Each gets its **own root credentials** (`accesskey`/`secretkey`) — keep
  them identical across both so the mirror + apps use one credential set,
  or give the mirror its own user on each.
- Re-create the IAM users (`mediawiki`, `attic`, `penpot`) on **both** via
  an init Job (`mc admin user add` + `mc admin policy attach`). The current
  setup lost IAM during the EC degradation; codify user creation as a Job so
  it is reproducible (see `tenant.yaml` / values for current user list).

### 3.2 Async mirror

A small Deployment running the MinIO client:

```sh
# one-way primary -> replica, continuous
mc alias set primary http://rustfs-chopper.rustfs-clusters.svc:9000 $AK $SK
mc alias set replica http://rustfs-c3po.rustfs-clusters.svc:9000     $AK $SK
mc mirror --watch --overwrite --remove primary replica
```

- `--watch` = continuous (event-driven) async sync → "replica may lag".
- This is **client-driven** (LIST/GET/PUT), so it works regardless of
  whether RustFS implements the server-side replication API. (If RustFS
  *does* support `mc replicate`, prefer native bucket replication — less
  moving parts.)
- For **failback** (writes that landed on the replica while the primary was
  down), run a reverse `mc mirror replica primary` pass when the primary
  returns, then resume forward mirroring. Easiest: a tiny controller/CronJob
  that mirrors both directions but only forward continuously; do a one-shot
  reverse sync on primary recovery.

### 3.3 Failover endpoint (nginx on kenobi)

nginx is the **single stable S3 endpoint** the apps point at. Put it on
`kenobi` (the reliable, non-storage node), 2 replicas, stateless:

```nginx
upstream rustfs {
    server rustfs-chopper.rustfs-clusters.svc:9000 max_fails=2 fail_timeout=10s;
    server rustfs-c3po.rustfs-clusters.svc:9000     backup;   # only on primary failure
}
server {
    listen 9000;
    client_max_body_size 0;          # large uploads
    proxy_request_buffering off;     # stream, don't buffer to disk
    location / {
        proxy_pass http://rustfs;
        proxy_next_upstream error timeout http_502 http_503 http_504;
    }
}
```

- Normal: everything hits `chopper`. `chopper` down → nginx fails to `c3po`.
- `chopper` returns → mirror catches it up → traffic fails back.
- Add an active health check (nginx `health_check` w/ NGINX Plus, or a
  sidecar that pulls a down backend, or just rely on `max_fails`/passive).
- Apps switch their S3 endpoint env to `http://<nginx-svc>:9000`.

> NOTE on which node is primary: prefer the node with the better uplink and
> stability as **primary**. Between `chopper` and `c3po`, pick whichever is
> more reliable; `c3po` (symmetric NAT, ~360 KB/s up) is the weaker one, so
> `chopper` as primary is the default above.

---

## 4. Migration runbook

Pre-req: cluster healthy (3/3 etcd), `mc` available, maintenance window
(uploads briefly read-only / paused for the affected apps).

1. **Stand up the two standalone tenants** alongside the existing EC set
   (different names/PVCs). Wait for both to be healthy & IAM users created.
2. **Seed the data**: `mc mirror <old-EC-endpoint> primary` to copy all
   existing buckets/objects from the current EC store into the new primary.
   Then `mc mirror primary replica` to seed the replica.
   - The current EC set is intermittently `Service not ready`; mirror with
     retries, off-peak. If the EC set can't serve at all, restore objects
     from off-site backups instead.
3. **Start continuous mirroring** primary→replica (`--watch`).
4. **Deploy the nginx failover proxy** on kenobi.
5. **Cut over apps** one at a time: point each app's S3 endpoint at the
   nginx Service, redeploy, verify uploads/reads. Order: penpot → attic →
   mediawiki (least → most critical), validating each.
6. **Decommission the EC tenant** (`tenant-ha.yaml`) once all apps are on the
   new endpoint and verified. Free its PVCs.
7. **Update the repo**: replace `tenant-ha.yaml` with the two standalone
   tenants + mirror + nginx; update `kustomization.yaml`; update
   `k8s/apps/rustfs/values.yaml`.

---

## 5. Endpoint exposure (tailnet vs Funnel vs Traefik)

Most S3 traffic is **in-cluster** (mediawiki/attic/penpot → ClusterIP) — that
stays internal and needs no external exposure.

For **tailnet** consumers (CI, laptop): use the **Tailscale operator
LoadBalancer** (`tailscale-s3-service.yaml`, `s3.tail477f2f.ts.net`). Tailnet
traffic routes **node-to-node over WireGuard directly** to the node hosting
the endpoint — it does **not** funnel through kenobi's Traefik, and it does
**not** go through Tailscale's throttled Funnel relays. Post-OCI-fix the
direct paths are fast. This is the best way to "not flood kenobi" **without**
Funnel's bandwidth limits.

**Funnel** (`tailscale-s3-funnel.yaml`) should be reserved for genuinely
**public** (non-tailnet) access only, and used cautiously: Tailscale Funnel is
**rate-limited and relays through Tailscale's infrastructure** (the same class
of throttling that motivated the self-hosted DERP), so it is a poor fit for
high-throughput object storage. If public high-throughput S3 is ever needed,
a public **Traefik IngressRoute on kenobi** (full bandwidth via kenobi's
public IP) is better than Funnel — at the cost of kenobi being the ingress
chokepoint. Summary:

| Consumer | Use | Why |
|---|---|---|
| In-cluster apps | ClusterIP Service | no exposure needed |
| Tailnet (CI, laptop) | Tailscale LB (`s3-tailscale`) | direct WireGuard node-to-node, full speed, no kenobi chokepoint, no Funnel throttle |
| Public, low volume | Funnel | simple, auto-TLS, off-kenobi ingress — but throttled |
| Public, high throughput | Traefik on kenobi | full bandwidth; kenobi is the chokepoint |

---

## 6. Tradeoffs & rollback

- **Tradeoff**: if the *primary* node dies, recent un-mirrored writes are the
  accepted "lag", and failover serves the replica's (slightly older) copy.
  This is availability, not zero-RPO — DR remains ZFS snapshots + backups.
- **No automatic multi-node durability within one store** (that was EC's
  theoretical benefit, which it wasn't actually delivering here). Durability
  = ZFS (local integrity/snapshots) on each node + the cross-node mirror +
  off-site backups.
- **Rollback**: the EC `tenant-ha.yaml` is unchanged until step 6. If the
  active-passive setup misbehaves, point apps back at the EC endpoint and
  tear down the new tenants.

---

## 7. Files touched (expected)

- `k8s/clusters/glug-infra/rustfs/tenant-ha.yaml` → removed/replaced by
  `tenant-chopper.yaml` + `tenant-c3po.yaml` (standalone).
- new `k8s/clusters/glug-infra/rustfs/mirror.yaml` (mc mirror Deployment).
- new `k8s/clusters/glug-infra/rustfs/s3-failover-nginx.yaml`.
- `k8s/clusters/glug-infra/rustfs/kustomization.yaml` (wire up the above).
- `k8s/apps/rustfs/values.yaml` (drop EC tenant config).
- app S3 endpoints (mediawiki/attic/penpot values) → nginx Service.
- keep `tailscale-s3-service.yaml`; treat `tailscale-s3-funnel.yaml` as
  public-only (see §5).
