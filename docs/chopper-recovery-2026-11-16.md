# Chopper recovery — 2026-11-16

## Starting state

- Continued from `lrrntspo` (network recovery) and `pnrtmtlr` (RustFS,
  PostgreSQL 18, and Eatsights).
- Chopper was reachable over Tailscale and SSH and had rejoined Kubernetes.
  Its active system was `dd6i7xr92mpc712ygz865411h2g6x0y4`, reporting
  `26.11.20260918.0a3468a`, with k3s `1.36.4+k3s1`.
- RustFS had only the C3po StatefulSet; the old primary and mirror were absent.
- Chopper's running system included Hermes Agent, its backend, Signal, and
  Tailscale Serve. Neither checked-out repository contained that configuration.
  The operator explicitly chose to retire Hermes as well as OpenClaw.

## Ghost recovery

All three MySQL Group Replication members were OFFLINE. ProxySQL had no writer
in hostgroup 10, and Ghost requests timed out. MySQL itself was writable on all
three members after their failed group joins.

Before recovery:

- Compared executed GTID sets on A/B/C: identical.
- Compared deterministic logical dumps of both `ghost` and `activitypub`,
  including schema, data, routines, events, and triggers: identical SHA-256
  `c90a9ec32b684bbbc2ce7e7edd336e4c67ca0982ff421af8783f26b35f1db237`.
- Each copy contained 81 Ghost tables, 22 ActivityPub tables, and 44 posts.
- Set `super_read_only=ON` on all three before taking a recovery backup.
- Streamed an all-databases dump from C3po, compressed and encrypted to the
  operator's master age recipient. The first uncompressed transfer failed;
  the successful compressed transfer used Kenobi's direct API endpoint.
- Verified decryption and gzip integrity. This is an integrity check, not a
  full database restore test.

Successful backup (private, outside the repository):

```text
/Users/mathew/.local/share/nix-recovery/2026-11-16/ghost-mgr.sql.gz.age
```

Bootstrapped exactly one group on member B (C3po), resetting the bootstrap flag
with an exit trap, then started Group Replication on A and C. No data directory
was replaced, no GTIDs were reset, and no clone/restore was required.

Verified all three members ONLINE, B PRIMARY, A/C SECONDARY. ProxySQL placed B
in writer hostgroup 10. A connection using Ghost's own application environment
resolved to `mysql-ghost-b-0`, and `https://tellmey.fyi` returned HTTP 200.

## Chopper configuration

- Removed the obsolete Nextcloud `adminuser` and `adminpassFile` settings
  that prevented evaluation against the current nixpkgs.
- Removed OpenClaw's service, Serve unit, package/input/plugin wiring, runtime
  secret declarations, insecure-package exception, and Android-TV mDNS port.
- Pruned OpenClaw/Signal-only lock inputs. Verified every retained dependency
  pin remained unchanged after lock-node renumbering.
- Evaluated assertions that assistant units/secrets are absent and Tailscale
  `extraSetFlags` match the configured startup flags.
- Target configuration: k3s `1.36.5+k3s1`, persistent Tailscale preferences, and
  `k3s-pod-routes.timer` scheduled minutely.

Deployment status: build/dry-activation in progress; final activation and
post-deploy checks are pending.

Runtime assistant state and encrypted credential entries are retained for
recovery. Provider credential revocation and Signal unlinking require checking
whether those credentials/devices are shared with other uses.

## Follow-up: Chopper leaves the cluster (same day)

Deployment status update: the earlier `nh os switch` on Chopper completed
(k3s 1.36.5; Hermes, Signal and OpenClaw stopped). Chopper was then removed
from k3s entirely.

Removed (user decision):

- **Cal.diy** and **Attic**: namespaces, Postgres databases and roles, and the
  `attic` bucket (1,343 objects, 297 MB). Encrypted `pg_dump` archives of both
  databases are under `~/.local/share/nix-recovery/2026-11-16/` on the Mac.
  Attic is also gone from CI and from every host's substituters.
- **Monitoring stack**: VictoriaMetrics, Grafana, VMAlert/Alertmanager,
  VictoriaLogs, the Vector log collector, node-exporter, kube-state-metrics,
  cloudprober, their CRDs, webhook and cluster RBAC.

Ghost MySQL: Group Replication was dissolved. Member B (C3po) is a standalone
writable server with `group_replication_start_on_boot` persisted OFF; it was
restarted to prove this. Ghost connects to it directly. Members A (Chopper)
and C (Kenobi), ProxySQL and their secrets are deleted. The hourly backup had
not succeeded since 2026-09-11; it is now a nightly dump to R2
(`mysql-ghost/`, 30 days), verified with a manual run.

Old RustFS volumes on Chopper were checked before deletion:

- The standalone primary (`data-rustfs-0`) matched C3po object-for-object by
  key, size and ETag in every bucket (Attic aside).
- The eight older volumes were one complete 8-drive erasure set from the
  operator era. Reassembled read-only from ZFS clones, it held **400 Penpot
  objects (9.5 MB) that existed nowhere else**; they were copied to C3po's
  `penpot` bucket and verified byte-for-byte. Everything else was already on
  C3po (old `mysql-backups` dumps were expired and not kept).

Then all of those volumes, the Ghost member A volume and the monitoring
volumes were deleted, Chopper was drained and deleted from the cluster, and
k3s was stopped on it. Routes to Chopper's old pod CIDR were removed from the
repo for every node and live on Kenobi and C3po (via a runtime-only systemd
drop-in until those hosts are redeployed). R2D2 now points at Kenobi.

Public buckets: `ghost` is anonymous-read for objects; `activitypub` for
`images/*` only. Both were set live and are not yet in the repo.
