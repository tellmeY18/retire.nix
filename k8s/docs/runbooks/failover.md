# Runbook: CNPG Failover

This runbook covers two scenarios:

1. **Planned switchover** — you initiate a graceful primary handover (e.g.
   before OS maintenance on the primary pod's node).
2. **Unplanned failover** — the primary pod or its node died unexpectedly.

---

## Prerequisites

- `kubectl` pointing at the chopper cluster.
- `kubectl-cnpg` plugin installed (`kubectl cnpg` commands below).
  Install: `kubectl krew install cnpg`  or grab the binary from
  <https://github.com/cloudnative-pg/cloudnative-pg/releases>.
- Access to the chopper tailnet.

---

## Check cluster and replication status

```shell
# Overview: primary, replicas, phase, continuous archiving status.
kubectl cnpg status chopper-pg -n cnpg-clusters

# Live streaming-replication lag for each standby.
kubectl exec -n cnpg-clusters -it chopper-pg-1 -- \
  psql -U postgres -c \
  "SELECT application_name, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
          (sent_lsn - replay_lsn) AS replication_lag
   FROM pg_stat_replication;"

# Check WAL archiving — last archived segment and any failures.
kubectl exec -n cnpg-clusters -it chopper-pg-1 -- \
  psql -U postgres -c "SELECT * FROM pg_stat_archiver;"
```

Pod naming convention: `chopper-pg-1` is typically the primary (index may
vary after failovers).  Use `kubectl cnpg status` to identify the current
primary by name.

---

## Scenario 1: Planned switchover (graceful)

Use this when you want to transfer the primary role to a specific replica
before a maintenance window.

```shell
# 1. Confirm which pod is currently the primary.
kubectl cnpg status chopper-pg -n cnpg-clusters

# 2. Initiate a graceful switchover to a target replica.
#    Replace 'chopper-pg-2' with the actual target pod name.
kubectl cnpg promote chopper-pg chopper-pg-2 -n cnpg-clusters

# 3. Watch the cluster transition.  The old primary will restart as a standby.
kubectl get pods -n cnpg-clusters -l cnpg.io/cluster=chopper-pg -w

# 4. Confirm the new primary.
kubectl cnpg status chopper-pg -n cnpg-clusters
```

**Expected timeline:** ~10–30 seconds for a graceful switchover.
Existing PgBouncer connections are dropped and retried; the webservice
connection pool should reconnect within its retry window (usually < 5 s).

---

## Scenario 2: Unplanned failover (primary node / pod died)

CNPG monitors the primary pod's health and automatically promotes the most
up-to-date synchronous standby when the primary is unreachable.

### What CNPG does automatically

1. Detects primary pod failure (liveness probe timeout, ~30 s).
2. Selects the synchronous standby with the highest `replay_lsn`.
3. Promotes it to primary (fences the old primary to prevent split-brain).
4. Updates the `chopper-pg-rw` Service endpoints.
5. PgBouncer reconnects to the new primary; Tailscale Service follows.

### What you need to do

```shell
# 1. Check cluster phase — should transition to "Failover in progress"
#    then "Cluster in healthy state".
kubectl get cluster chopper-pg -n cnpg-clusters -o wide -w

# 2. Once healthy, confirm the new primary.
kubectl cnpg status chopper-pg -n cnpg-clusters

# 3. Confirm WAL archiving resumed on the new primary.
kubectl exec -n cnpg-clusters -it <new-primary-pod> -- \
  psql -U postgres -c "SELECT last_archived_wal, last_failed_wal FROM pg_stat_archiver;"

# 4. If the failed node comes back online, its pod will rejoin as a standby
#    automatically — no manual intervention needed.
```

### If the node running chopper-pg-1 is gone and CNPG does NOT auto-promote

This can happen if the `synchronous` quorum is not satisfied (e.g. all
standbys were also on the dead node).  In that case:

```shell
# Force-promote the most recent standby (use with care — possible data loss
# if the old primary had uncommitted sync writes).
kubectl cnpg promote chopper-pg <standby-pod-name> -n cnpg-clusters --force
```

---

## Scenario 3: Full node loss (chopper is the only node — Phase 1)

> **Warning:** In Phase 1 (single node), all CNPG pods are on chopper.  If
> chopper goes down, **no automatic failover is possible**.  The cluster is
> unavailable until chopper is restored or you restore from the S3 backup.
>
> See [`restore-pitr.md`](restore-pitr.md) for PITR restore instructions.
> See [`add-node.md`](add-node.md) to add a second node and reduce this risk.

Recovery steps when chopper comes back:

```shell
# 1. Check that k3s and CNPG pods come up cleanly.
kubectl get pods -n cnpg-clusters -w

# 2. Check cluster phase.
kubectl cnpg status chopper-pg -n cnpg-clusters

# 3. Check archiving resumed.
kubectl exec -n cnpg-clusters -it chopper-pg-1 -- \
  psql -U postgres -c "SELECT last_archived_wal FROM pg_stat_archiver;"
```

---

## Post-failover checklist

- [ ] `kubectl cnpg status` shows "Cluster in healthy state".
- [ ] All 3 instances are Running.
- [ ] WAL archiving is active (`last_failed_wal` is empty or old).
- [ ] ScheduledBackup produces a successful Backup object:
      `kubectl get backup -n cnpg-clusters`
- [ ] Webservice connection string (`pg-rw.<tailnet>.ts.net:5432`) is reachable.
- [ ] Replication lag is 0 or near-0 on standbys.
