# MySQL Failover: `mysql-ghost` MGR Auto-Promotion

> **Status:** Live. The old PXC + RAM-replica + standalone-ProxySQL failover
> design described here previously is gone (PXC decommissioned). Ghost now runs
> on a 3-member MySQL Group Replication cluster that fails over on its own.

## Goal

If the current MGR primary (`mysql-ghost-a` on chopper) or its node goes
offline, the group should automatically elect a new primary from the surviving
members, and `proxysql-ghost` should re-route writes to it with no manual
intervention. When the original member returns it rejoins as a secondary.

This is genuinely HA: it survived a real chopper node failure with automatic
failover during deployment.

## Architecture

```
Ghost / ActivityPub
       │
   proxysql-ghost (kenobi, namespace mysql-ghost)
       ├── hostgroup 10 (WRITER) → current MGR primary
       └── hostgroup 20 (READER) → secondaries (auto-discovered)
       │
   MGR (single-primary, group_replication)
       ├── mysql-ghost-a  chopper, ZFS   weight 50  (preferred primary)
       ├── mysql-ghost-b  c3po, ZFS      weight 40  (secondary)
       └── mysql-ghost-c  kenobi, hostPath weight 10 (quorum-only, never primary)
```

- 3 members tolerate **one** failure (majority = 2/3). Losing one storage node
  keeps the group writable; the primary fails over to the survivor.
- `proxysql-ghost`'s MGR monitor reads `sys.gr_member_routing_candidate_status`
  on each member to discover which one is the writable primary, and keeps that
  member in writer hostgroup 10.
- Member weights bias the election: `a` is preferred, then `b`; `c` (the kenobi
  quorum vote) only ever becomes primary if it is the last survivor.

## How automatic failover works

1. The primary pod or its node dies.
2. MGR detects the loss and, with a surviving majority, elects a new primary
   (highest-weight ONLINE member). `group_replication_consistency=BEFORE_ON_PRIMARY_FAILOVER`
   narrows the window of in-flight transactions.
3. `proxysql-ghost`'s monitor sees the new primary report
   `viable_candidate=YES, read_only=NO` via the routing view and moves it into
   hostgroup 10; the demoted/old member is dropped from HG10.
4. Ghost's connection pool reconnects; clients see at most a brief drop.
5. When the failed member returns, `group_replication_start_on_boot=ON` rejoins
   it as a secondary (cloning from the group if it fell too far behind).

No failover sidecar, no manual promotion, no async-replica toggling — MGR owns
the election and ProxySQL owns the routing.

## Quorum caveat

Because `mysql-ghost-c` counts toward the write majority, the last few committed
transactions may live only on `primary + c`; if both die simultaneously the
surviving storage node is in the minority and the group goes **read-only** until
quorum returns. This is accepted for a low-write blog. If the group is stuck in
the minority, recover with the runbook in
[`../../docs/mysql-ghost-mgr.md`](../../docs/mysql-ghost-mgr.md) (§7 Day-2).

## MediaWiki is not in this path

MediaWiki runs on the **standalone single-node** `mysql-mediawiki` (kenobi,
hostPath) — deliberately kept off MGR because its schema has 52
primary-key-less tables (MediaWiki core + SemanticMediaWiki `smw_*` + Cargo
`cargo_*`) and Group Replication requires a primary key on every table. There is
**no automatic failover** for MediaWiki: while kenobi is down, MediaWiki's MySQL
is simply down. Protection is the hourly logical backup to S3 — recover by
restoring the latest dump.

## Monitoring & alerts

VictoriaMetrics rules (`monitoring/mysql-ghost-vmrules.yaml`) alert on:

- `MGRMemberOffline` — a member is not `ONLINE` in
  `performance_schema.replication_group_members`.
- `MGRNoPrimary` — the group has no member in the `PRIMARY` role.
- `MGRReadOnly` — the group lost quorum and went read-only.
- `MGRReplicationLagHigh` — a secondary's apply queue is growing.

## Manual operations

```sh
ROOT=$(kubectl get secret -n mysql-ghost mysql-ghost-root -o jsonpath='{.data.password}' | base64 -d)

# Current membership / which member is PRIMARY:
kubectl exec -n mysql-ghost mysql-ghost-a-0 -c mysql -- \
  mysql -uroot -p"$ROOT" -e \
  "SELECT member_host, member_state, member_role \
   FROM performance_schema.replication_group_members;"

# ProxySQL routing view (admin on :6032):
kubectl exec -n mysql-ghost deploy/proxysql-ghost -- \
  mysql -uradmin -p... -h127.0.0.1 -P6032 -e \
  "SELECT hostgroup_id,hostname,status FROM runtime_mysql_servers;"

# Kick a member that landed in ERROR state back into the group:
kubectl exec -n mysql-ghost mysql-ghost-c-0 -c mysql -- \
  mysql -uroot -p"$ROOT" -e "STOP GROUP_REPLICATION; START GROUP_REPLICATION;"
```

For the full bootstrap, ProxySQL routing-view setup, clone-based rejoin, and
restore-from-S3 procedures, see
[`../../docs/mysql-ghost-mgr.md`](../../docs/mysql-ghost-mgr.md).
