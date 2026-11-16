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
