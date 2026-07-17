# Ghost MySQL — Group Replication (MGR) runbook

Ghost's database is a 3-member **MySQL Group Replication** cluster
(single-primary), fronted by a dedicated **ProxySQL**. It replaces the
decommissioned PXC operator cluster and is independent of `pxc-ram`
(MediaWiki's MySQL).

```
                         ┌─────────────────────────────┐
   Ghost pods ──3306──▶  │ proxysql-ghost  (kenobi)     │
                         │  HG10 writer / HG20 reader   │
                         └───────┬─────────────┬────────┘
                                 │             │
                    ┌────────────▼──┐   ┌──────▼────────┐
                    │ member-a      │   │ member-b      │
                    │ chopper, ZFS  │◀─▶│ c3po, ZFS     │
                    │ weight 50 (P) │   │ weight 40     │
                    └───────┬───────┘   └──────┬────────┘
                            │   MGR (33061)     │
                            └────────┬──────────┘
                                     │
                            ┌────────▼────────┐
                            │ member-c        │  quorum-only, weight 10
                            │ kenobi, hostPath│  never primary, no app traffic
                            └─────────────────┘
```

## HA reality check

- **3 members → tolerates 1 failure** (majority = 2/3). Losing one storage
  node keeps the group writable; the primary fails over to the survivor.
- `member-c` is **not** a lightweight arbiter — MGR has none. It is a full
  data node on ephemeral-ish hostPath whose only job is the third vote.
  Because it counts toward the write majority, the last few committed
  transactions could live on `primary + c` only; if both die at once, those
  are lost while the surviving storage node is in the minority. Accepted for
  a low-write blog; `group_replication_consistency=BEFORE_ON_PRIMARY_FAILOVER`
  narrows the window.

---

## 0. Prerequisites

1. **kenobi hostPath** — apply the NixOS change that creates
   `/var/lib/mysql-ghost`:
   ```sh
   nh os switch   # on/for kenobi (hosts/kenobi/parts/storage.nix)
   ```
2. **Secrets** (namespace `mysql-ghost`) — `mysql-ghost-root`,
   `mysql-ghost-app`, `mysql-ghost-backup-s3` already exist. Create the
   ProxySQL config secret (see §4).
3. `kubectl` pointed at glug-infra.

---

## 1. Apply the manifests

```sh
kubectl apply -k k8s/clusters/glug-infra/mysql-ghost
```

All three members come up **freshly initialised and standalone** (each runs
the percona entrypoint, creating an empty `ghost` DB + `ghost` user). They do
NOT auto-form a group yet — we bootstrap deliberately so GTIDs stay clean.

```sh
kubectl get pods -n mysql-ghost -o wide   # a→chopper, b→c3po, c→kenobi, all Running
```

Helper:
```sh
ROOT=$(kubectl get secret -n mysql-ghost mysql-ghost-root -o jsonpath='{.data.password}' | base64 -d)
m() { kubectl exec -i -n mysql-ghost "mysql-ghost-$1-0" -c mysql -- mysql -uroot -p"$ROOT" "${@:2}"; }
```

---

## 2. Get the up-to-date Ghost data from PXC

The current `ghost` data lives in the (down) PXC cluster on chopper. Revive it
just long enough to dump.

```sh
# Let the PXC data pod schedule onto chopper (where its ZFS PV lives) by
# tolerating the storage taint.
kubectl patch pxc mysql-pxc-db -n pxc-clusters --type merge \
  -p '{"spec":{"pxc":{"tolerations":[{"key":"node-role.glug.infra/storage","operator":"Equal","value":"true","effect":"NoSchedule"}]}}}'

kubectl -n pxc-clusters rollout status statefulset/mysql-pxc-db-pxc --timeout=10m
# If Galera refuses to bootstrap (not safe_to_bootstrap), set
# spec.pxc.forceUnsafeBootstrap=true on the CR, or restore from the most
# recent xb-cron S3 backup instead (see §7 fallback).

PXC_ROOT=$(kubectl get secret -n pxc-clusters internal-mysql-pxc-db -o jsonpath='{.data.root}' | base64 -d)
kubectl exec -n pxc-clusters mysql-pxc-db-pxc-0 -c pxc -- \
  mysqldump -uroot -p"$PXC_ROOT" --databases ghost \
    --single-transaction --routines --triggers --events \
    --set-gtid-purged=OFF > /tmp/ghost.sql

grep -c 'INSERT INTO' /tmp/ghost.sql   # sanity: non-zero
```

---

## 3. Bootstrap the group

GR plugins and `group_replication_*` settings are applied here at runtime
(NOT in the static config — see mgr-config.yaml header). `INSTALL PLUGIN`
persists in `mysql.plugin` and `SET PERSIST` writes `mysqld-auto.cnf`, so both
survive restarts and the members self-heal after a reboot.

### 3a. Configure GR on every member

```sh
# Per-member specifics: local GR address + election weight.
declare -A LADDR=(
  [a]=mysql-ghost-a-0.mysql-ghost-a.mysql-ghost.svc.cluster.local:33061
  [b]=mysql-ghost-b-0.mysql-ghost-b.mysql-ghost.svc.cluster.local:33061
  [c]=mysql-ghost-c-0.mysql-ghost-c.mysql-ghost.svc.cluster.local:33061
)
declare -A WEIGHT=( [a]=50 [b]=40 [c]=10 )   # c lowest → never primary
SEEDS="${LADDR[a]},${LADDR[b]},${LADDR[c]}"
REPL_PW='CHANGEME_REPL_PW'

for n in a b c; do
  m "$n" <<SQL
INSTALL PLUGIN group_replication SONAME 'group_replication.so';
INSTALL PLUGIN clone SONAME 'mysql_clone.so';
SET PERSIST group_replication_group_name='5b9e7a1c-4f3d-4c2a-9b8e-1a2b3c4d5e6f';
SET PERSIST group_replication_single_primary_mode=ON;
SET PERSIST group_replication_enforce_update_everywhere_checks=OFF;
SET PERSIST group_replication_ssl_mode='DISABLED';
SET PERSIST group_replication_recovery_use_ssl=OFF;
SET PERSIST group_replication_recovery_get_public_key=ON;
SET PERSIST group_replication_consistency='BEFORE_ON_PRIMARY_FAILOVER';
SET PERSIST group_replication_autorejoin_tries=2016;
SET PERSIST group_replication_member_expel_timeout=30;
SET PERSIST group_replication_unreachable_majority_timeout=300;
SET PERSIST group_replication_exit_state_action='READ_ONLY';
SET PERSIST group_replication_ip_allowlist='10.42.0.0/16,127.0.0.1/8';
SET PERSIST group_replication_group_seeds='${SEEDS}';
SET PERSIST group_replication_local_address='${LADDR[$n]}';
SET PERSIST group_replication_member_weight=${WEIGHT[$n]};
SET PERSIST group_replication_start_on_boot=ON;
-- recovery channel user (distributed recovery / clone)
SET SQL_LOG_BIN=0;
CREATE USER IF NOT EXISTS 'gr_repl'@'%' IDENTIFIED BY '${REPL_PW}';
GRANT REPLICATION SLAVE, BACKUP_ADMIN, CLONE_ADMIN, CONNECTION_ADMIN, GROUP_REPLICATION_STREAM ON *.* TO 'gr_repl'@'%';
FLUSH PRIVILEGES;
SET SQL_LOG_BIN=1;
CHANGE REPLICATION SOURCE TO SOURCE_USER='gr_repl', SOURCE_PASSWORD='${REPL_PW}' FOR CHANNEL 'group_replication_recovery';
SQL
done
```

### 3b. Seed member-a (the primary) with data, then bootstrap

```sh
m a -e "RESET MASTER;"                 # clear GTIDs from the entrypoint init
m a ghost < /tmp/ghost.sql             # load the PXC dump (becomes a's GTIDs)
m a <<'SQL'
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;
SQL
m a -e "SELECT member_host, member_state, member_role FROM performance_schema.replication_group_members;"
# → member-a ONLINE PRIMARY
```

### 3c. Join member-b and member-c via clone

```sh
for n in b c; do
  m "$n" <<'SQL'
RESET MASTER;
SET GLOBAL group_replication_clone_threshold=1;   -- force a full clone from a
START GROUP_REPLICATION;
SQL
done

# Watch them clone + come ONLINE (RECOVERING → ONLINE). The clone plugin
# auto-restarts the joiner once; start_on_boot=ON brings GR back up.
watch -n3 "kubectl exec -n mysql-ghost mysql-ghost-a-0 -c mysql -- \
  mysql -uroot -p\"$ROOT\" -e \
  'SELECT member_host,member_state,member_role FROM performance_schema.replication_group_members;'"
# → 3 rows, all ONLINE, exactly one PRIMARY (member-a).

# Clone replaces the joiner's datadir — confirm each member's GR address is
# still its OWN (re-SET PERSIST + restart GR for any that drifted).
for n in a b c; do echo -n "$n: "; m "$n" -N -e "SELECT @@group_replication_local_address;"; done
```

Verify the data landed on a secondary:
```sh
m b ghost -e "SELECT COUNT(*) posts FROM posts; SELECT MAX(updated_at) FROM posts;"
```

---

## 4. ProxySQL config

Create the routing view ProxySQL's MGR monitor reads. Two gotchas learned in
practice: (a) a single-`RETURN` function body avoids `DELIMITER` juggling, and
(b) a view may not reference `@@server_uuid` directly (error 1351) so wrap it
in a helper function. Run on the primary (replicates to the group):

```sh
m a <<'SQL'
DROP FUNCTION IF EXISTS sys.gr_member_in_primary_partition;
CREATE FUNCTION sys.gr_member_in_primary_partition() RETURNS VARCHAR(3) DETERMINISTIC
RETURN (SELECT IF(MEMBER_STATE='ONLINE' AND ((SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE != 'ONLINE') >= ((SELECT COUNT(*) FROM performance_schema.replication_group_members)/2) = 0), 'YES','NO') FROM performance_schema.replication_group_members JOIN performance_schema.replication_group_member_stats rgms USING(member_id) WHERE rgms.MEMBER_ID=@@SERVER_UUID);
DROP FUNCTION IF EXISTS sys.gr_local_member_id;
CREATE FUNCTION sys.gr_local_member_id() RETURNS CHAR(36) DETERMINISTIC NO SQL RETURN @@server_uuid;
CREATE OR REPLACE VIEW sys.gr_member_routing_candidate_status AS
SELECT sys.gr_member_in_primary_partition() AS viable_candidate,
  IF((SELECT (SELECT GROUP_CONCAT(variable_value) FROM performance_schema.global_variables WHERE variable_name IN ('read_only','super_read_only')) != 'OFF,OFF'),'YES','NO') AS read_only,
  Count_Transactions_Remote_In_Applier_Queue AS transactions_behind,
  Count_Transactions_in_queue AS transactions_to_cert
FROM performance_schema.replication_group_member_stats a
JOIN performance_schema.replication_group_members b ON a.member_id=b.member_id
WHERE b.member_id=sys.gr_local_member_id();
SQL
```

Monitor user — needs `mysql_native_password` (ProxySQL connects without SSL),
plus SELECT on **both** `sys` and `performance_schema` (ProxySQL queries
`replication_group_members` directly, not only via the view):

```sh
MON_PW=$(kubectl get secret -n mysql-ghost mysql-ghost-gr -o jsonpath='{.data.monitor_password}' | base64 -d)
m a <<SQL
CREATE USER IF NOT EXISTS 'gr_mon'@'%' IDENTIFIED WITH mysql_native_password BY '${MON_PW}';
GRANT SELECT ON sys.* TO 'gr_mon'@'%';
GRANT SELECT ON performance_schema.* TO 'gr_mon'@'%';
GRANT REPLICATION CLIENT, PROCESS ON *.* TO 'gr_mon'@'%';
SQL
```

ProxySQL config Secret (`proxysql-ghost-config`, key `proxysql.cnf`) — fill in
the `gr_mon` monitor password, the `ghost` app password (= `mysql-ghost-app`),
and a `radmin` password, then sops-encrypt for the repo:

```ini
datadir="/var/lib/proxysql"
admin_variables={ admin_credentials="admin:admin;radmin:CHANGEME"; mysql_ifaces="0.0.0.0:6032" }
mysql_variables={
  threads=2
  interfaces="0.0.0.0:3306"
  server_version="8.0.45"
  monitor_username="gr_mon"
  monitor_password="CHANGEME_MON_PW"
  monitor_read_only_interval=1500
  monitor_read_only_timeout=500
}
mysql_group_replication_hostgroups=(
  { writer_hostgroup=10, backup_writer_hostgroup=11, reader_hostgroup=20,
    offline_hostgroup=12, active=1, max_writers=1, writer_is_also_reader=1,
    max_transactions_behind=100 }
)
mysql_servers=(
  { address="mysql-ghost-a-0.mysql-ghost-a.mysql-ghost.svc.cluster.local", port=3306, hostgroup=10, max_connections=200 },
  { address="mysql-ghost-b-0.mysql-ghost-b.mysql-ghost.svc.cluster.local", port=3306, hostgroup=10, max_connections=200 }
)
mysql_users=(
  { username="ghost", password="CHANGEME_GHOST_PW", default_hostgroup=10, transaction_persistent=1, active=1 }
)
```

> No `mysql_query_rules` are defined, so ALL Ghost traffic goes to the
> default hostgroup (10 = primary). Members b/c therefore receive no
> application queries; c (kenobi quorum) only ever serves as primary if it's
> the last survivor. ProxySQL's GR monitor auto-discovers c into the reader
> hostgroup, but nothing routes there without query rules.

```sh
sops --decrypt k8s/clusters/glug-infra/mysql-ghost/proxysql-ghost-config.enc.yaml | kubectl apply -f -
kubectl rollout restart deploy/proxysql-ghost -n mysql-ghost
```

Verify routing (admin on :6032):
```sh
kubectl exec -n mysql-ghost deploy/proxysql-ghost -- \
  mysql -uradmin -pCHANGEME -h127.0.0.1 -P6032 -e \
  "SELECT hostgroup_id,hostname,status FROM runtime_mysql_servers;"
# → primary in HG10, secondary in HG20.
```

---

## 5. Cut Ghost over

The Ghost deployment already points at `proxysql-ghost.mysql-ghost.svc:3306`.

```sh
kubectl apply -k k8s/clusters/glug-infra/ghost
kubectl rollout restart deploy/ghost -n ghost
kubectl rollout status deploy/ghost -n ghost
curl -fsS https://tellmey.fyi/ghost/api/admin/site/ >/dev/null && echo OK
```

---

## 6. Decommission PXC

Once Ghost is verified healthy on the new cluster:

```sh
kubectl delete pxc mysql-pxc-db -n pxc-clusters
kubectl delete namespace pxc-clusters
# remove k8s/clusters/glug-infra/pxc from the repo + the Justfile apply list,
# and update CLAUDE.md §8 (PXC) to reflect MGR.
```

---

## 7. Day-2

- **Status:** `m a -e "SELECT member_host,member_state,member_role FROM performance_schema.replication_group_members;"`
- **Backups:** hourly `mysql-ghost-backup` CronJob → `s3://mysql-backups/ghost/`.
- **Restore fallback (no PXC):** `gunzip -c <dump>.sql.gz | m a ghost` after a
  fresh bootstrap of member-a, then rejoin b/c (§3b).
- **After a kenobi reboot:** member-c rejoins automatically
  (`group_replication_start_on_boot=ON`, hostPath persisted). If it landed in
  ERROR state, `m c -e "STOP GROUP_REPLICATION; START GROUP_REPLICATION;"`.

### Self-healing tuning

These settings (applied via `SET PERSIST` in §3a) are critical for
unattended recovery:

| Setting | Value | Why |
|---|---|---|
| `autorejoin_tries` | **2016** | Retry every 5 min for 7 days before giving up |
| `member_expel_timeout` | **30** | Tolerate 30s network blip before expelling |
| `unreachable_majority_timeout` | **300** | Don't hang forever on quorum loss; go read-only after 5 min so auto-rejoin can kick in |
| `start_on_boot` | **ON** | Rejoin after pod/node restart |

With the defaults (`autorejoin_tries=3`) a member gives up after ~15 min
and sits in READ_ONLY permanently until a human intervenes. The values
above keep the cluster self-healing for up to a week of downtime.

If all members end up OFFLINE/ERROR simultaneously (total quorum loss),
manual re-bootstrap is still required — see §3b.
