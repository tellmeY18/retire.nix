# Runbook: Point-in-Time Recovery (PITR)

This runbook restores the `chopper-pg` PostgreSQL cluster from the off-site
Barman Cloud S3 backup into a **new namespace** (`cnpg-restore`).  Restoring
into a fresh namespace means the production cluster in `cnpg-clusters` is
untouched until you are ready to cut over.

---

## When to use this runbook

- Accidental data deletion or corruption.
- Disaster recovery when chopper is lost and needs a full rebuild.
- Validation of backup integrity (dry-run restore into a test namespace).

---

## Prerequisites

- `kubectl` pointing at the cluster (or a fresh cluster if rebuilding).
- CNPG operator running in `cnpg-system`.
- The `cnpg-backup-s3` Secret with valid S3 credentials (apply it first in
  the restore namespace).
- The target recovery time in UTC (e.g. `"2024-06-01T03:45:00"`)  — identify
  this from application logs before starting.

---

## Step 1 — Identify the recovery target time

```shell
# Check available base backups and their start/stop times.
kubectl cnpg backup list chopper-pg -n cnpg-clusters

# Or list Backup objects directly.
kubectl get backup -n cnpg-clusters \
  -o custom-columns="NAME:.metadata.name,STARTED:.status.startedAt,STOPPED:.status.stoppedAt,STATUS:.status.phase"
```

Note the `beginWal` and `endWal` fields from the most recent successful backup
before your target time.  Your target time must be:

- **After** the start of the earliest available base backup.
- **Before** the current time (CNPG cannot restore into the future).

---

## Step 2 — Create the restore namespace and apply S3 credentials

```shell
kubectl create namespace cnpg-restore

# Decrypt and apply the S3 credentials Secret into the new namespace.
# Edit the namespace field in a temp copy, or use kubectl patch after apply.
sops --decrypt k8s/clusters/chopper/secrets/cnpg-backup-s3.enc.yaml \
  | sed 's/namespace: cnpg-clusters/namespace: cnpg-restore/' \
  | kubectl apply -f -

# Verify the Secret is present.
kubectl get secret cnpg-backup-s3 -n cnpg-restore
```

---

## Step 3 — Create the recovery Cluster manifest

Create a temporary file (do **not** commit it — it is a one-shot operation):

```yaml
# /tmp/cnpg-restore-cluster.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: chopper-pg-restore
  namespace: cnpg-restore
spec:
  instances: 1

  storage:
    storageClass: zfs-localpv
    size: 20Gi

  bootstrap:
    recovery:
      # Point at the same S3 destination used by the production cluster.
      backup:
        name: ""         # Leave empty; source is the barmanObjectStore below.
      source: chopper-pg-backup

      # -----------------------------------------------------------------------
      # Recovery target — set this to your desired point in time.
      # CNPG will replay WAL until this timestamp then stop.
      # -----------------------------------------------------------------------
      recoveryTarget:
        targetTime: "YYYY-MM-DDTHH:MM:SS"   # ← REPLACE THIS

  externalClusters:
    - name: chopper-pg-backup
      barmanObjectStore:
        destinationPath: "s3://YOUR-BUCKET-NAME/chopper-pg"   # ← same as production
        # endpointURL: "https://YOUR-S3-ENDPOINT"             # ← uncomment if needed
        s3Credentials:
          accessKeyId:
            name: cnpg-backup-s3
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: cnpg-backup-s3
            key: SECRET_ACCESS_KEY
        wal:
          maxParallel: 4

  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
```

Key fields to edit:

| Field | Action |
|---|---|
| `recoveryTarget.targetTime` | Set to your desired recovery point in UTC ISO-8601 format. |
| `externalClusters[].barmanObjectStore.destinationPath` | Must exactly match the production cluster's `destinationPath`. |
| `externalClusters[].barmanObjectStore.endpointURL` | Uncomment if using non-AWS S3. |

---

## Step 4 — Apply and monitor the recovery

```shell
kubectl apply -f /tmp/cnpg-restore-cluster.yaml

# Watch pod startup and recovery progress.
kubectl get pods -n cnpg-restore -w

# Follow the recovery logs on the restore pod.
kubectl logs -n cnpg-restore chopper-pg-restore-1 -f

# Check cluster phase — you want "Cluster in healthy state".
kubectl cnpg status chopper-pg-restore -n cnpg-restore
```

The restore pod will:

1. Download the latest base backup before `targetTime` from S3.
2. Replay WAL segments from S3 until `targetTime` is reached.
3. Promote the instance and come up read-write.

This can take several minutes depending on how much WAL needs replaying and
your S3 download speed.

---

## Step 5 — Validate the restored data

```shell
# Connect to the restored cluster using the auto-generated credentials.
kubectl cnpg psql chopper-pg-restore -n cnpg-restore -- -U app -d app

# Inside psql — check a timestamp that should be after your corruption event
# to confirm data is NOT there, and data before the target IS there.
SELECT now();   -- should be close to your targetTime
\dt             -- list tables
-- run application-specific validation queries
\q
```

---

## Step 6 — Cut over (optional)

If the restored data looks correct and you want to promote it to production:

```shell
# 1. Scale down application workloads pointing at chopper-pg.

# 2. Take a final backup of the restored cluster.
kubectl cnpg backup chopper-pg-restore -n cnpg-restore

# 3. Rename / re-namespace as needed, OR update the Tailscale Service selector
#    to point at the restore cluster's Pooler.

# 4. Delete the production cluster (DESTRUCTIVE — confirm first).
#    kubectl delete cluster chopper-pg -n cnpg-clusters

# 5. Apply a new production cluster bootstrapped from the restore point.
#    Use the same recovery manifest but target namespace cnpg-clusters and
#    cluster name chopper-pg.
```

---

## Step 7 — Cleanup

```shell
# Remove the restore namespace once you are done.
kubectl delete namespace cnpg-restore
rm /tmp/cnpg-restore-cluster.yaml
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Pod stuck in `Init` or `Pending` | PVC not bound (StorageClass issue) | Check `kubectl get pvc -n cnpg-restore` and OpenEBS ZFS LocalPV controller logs. |
| `ERROR: WAL file not found` | Gap in WAL on S3 or wrong `destinationPath` | Verify `destinationPath` matches production exactly; check `barman-cloud-wal-list`. |
| Recovery stops before `targetTime` | `targetTime` is in the future or beyond available WAL | Use an earlier `targetTime`; check `pg_stat_archiver` on the last healthy backup. |
| Pod `CrashLoopBackOff` on restore pod | PostgreSQL startup error | `kubectl logs -n cnpg-restore chopper-pg-restore-1 --previous` for the crash reason. |
| `AccessDenied` on S3 | Wrong credentials in Secret | Re-apply the decrypted Secret; check bucket policy. |
