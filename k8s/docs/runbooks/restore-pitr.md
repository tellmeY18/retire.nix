# Runbook: Point-in-Time Recovery (PITR)

This runbook restores the `postgres` PostgreSQL cluster from the off-site
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
- An S3 credentials Secret (named `postgres-backup` in the production
  namespace; we will copy it into the restore namespace in Step 2).
- The destinationPath the production cluster uses — read it directly
  from the running Cluster CR rather than re-deriving it from values:
    kubectl get cluster postgres -n cnpg-clusters -o jsonpath='{.spec.backup.barmanObjectStore.destinationPath}'
- The endpointURL (if non-AWS S3); same trick:
    kubectl get cluster postgres -n cnpg-clusters -o jsonpath='{.spec.backup.barmanObjectStore.endpointURL}'
- The target recovery time in UTC (e.g. `"2024-06-01T03:45:00"`) — identify
  this from application logs before starting.

---

## Step 1 — Identify the recovery target time

```shell
# Check available base backups and their start/stop times.
kubectl cnpg backup list postgres -n cnpg-clusters

# Or list Backup objects directly.
kubectl get backup -n cnpg-clusters \
  -o custom-columns="NAME:.metadata.name,STARTED:.status.startedAt,STOPPED:.status.stoppedAt,STATUS:.status.phase"
```

Note the `beginWal` and `endWal` fields from the most recent successful backup
before your target time.  Your target time must be:

- **After** the start of the earliest available base backup.
- **Before** the current time (CNPG cannot restore into the future).

---

## Step 2 — Create the restore namespace and copy S3 credentials

The chart creates a `postgres-backup` Secret in `cnpg-clusters` from the
values in `k8s/apps/postgres/secrets.yaml`. To avoid duplicating sops
decrypt work, copy the live Secret into the restore namespace.

```shell
kubectl create namespace cnpg-restore

# Copy the chart-rendered Secret across namespaces.
kubectl get secret postgres-backup -n cnpg-clusters -o json \
  | jq 'del(.metadata.namespace, .metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.ownerReferences) | .metadata.namespace = "cnpg-restore"' \
  | kubectl apply -f -

# Verify the Secret is present.
kubectl get secret postgres-backup -n cnpg-restore
```

If you are restoring on a *fresh* cluster (chopper rebuilt from scratch),
the `postgres-backup` Secret does not yet exist. In that case decrypt the
sops-encrypted helm values directly and create the Secret by hand:

```shell
sops --decrypt k8s/apps/postgres/secrets.yaml > /tmp/pg-secrets.yaml
# /tmp/pg-secrets.yaml contains backups.s3.{accessKey,secretKey}
kubectl create secret generic postgres-backup -n cnpg-restore \
  --from-literal=ACCESS_KEY_ID="$(yq '.backups.s3.accessKey' /tmp/pg-secrets.yaml)" \
  --from-literal=ACCESS_SECRET_KEY="$(yq '.backups.s3.secretKey' /tmp/pg-secrets.yaml)"
rm /tmp/pg-secrets.yaml
```

---

## Step 3 — Create the recovery Cluster manifest

Create a temporary file (do **not** commit it — it is a one-shot operation):

```yaml
# /tmp/cnpg-restore-cluster.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-restore
  namespace: cnpg-restore
spec:
  instances: 1

  # Match the production image so collations / catalog versions agree.
  imageName: ghcr.io/cloudnative-pg/postgresql:17.2-bookworm

  storage:
    storageClass: zfs-localpv
    size: 20Gi
  walStorage:
    storageClass: zfs-localpv
    size: 5Gi

  bootstrap:
    recovery:
      # Pull from the named externalCluster declared below. The operator
      # finds the latest base backup in the object store before targetTime,
      # then replays WAL until targetTime is hit.
      source: postgres-backup
      recoveryTarget:
        # ---------------------------------------------------------------
        # Recovery target — set this to your desired point in time (UTC).
        # CNPG will replay WAL until this timestamp then stop.
        # ---------------------------------------------------------------
        targetTime: "YYYY-MM-DDTHH:MM:SS"   # ← REPLACE THIS

  externalClusters:
    - name: postgres-backup
      barmanObjectStore:
        # Must EXACTLY match the production cluster's destinationPath.
        # Read it from the live Cluster:
        #   kubectl get cluster postgres -n cnpg-clusters \
        #     -o jsonpath='{.spec.backup.barmanObjectStore.destinationPath}'
        destinationPath: "s3://glug-infra-pg-backups/postgres"
        # endpointURL: "https://YOUR-S3-ENDPOINT"   # uncomment for R2/B2/Garage
        s3Credentials:
          accessKeyId:
            name: postgres-backup
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: postgres-backup
            key: ACCESS_SECRET_KEY
        wal:
          maxParallel: 4

  resources:
    requests:
      memory: "512Mi"
      cpu: "100m"
    limits:
      memory: "1.5Gi"
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
kubectl logs -n cnpg-restore postgres-restore-1 -f

# Check cluster phase — you want "Cluster in healthy state".
kubectl cnpg status postgres-restore -n cnpg-restore
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
kubectl cnpg psql postgres-restore -n cnpg-restore -- -U app -d app

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
# 1. Scale down application workloads pointing at postgres.

# 2. Take a final backup of the restored cluster.
kubectl cnpg backup postgres-restore -n cnpg-restore

# 3. Rename / re-namespace as needed, OR update the Tailscale Service selector
#    to point at the restore cluster's Pooler.

# 4. Delete the production cluster (DESTRUCTIVE — confirm first).
#    kubectl delete cluster postgres -n cnpg-clusters

# 5. Apply a new production cluster bootstrapped from the restore point.
#    Use the same recovery manifest but target namespace cnpg-clusters and
#    cluster name postgres.
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
| Pod `CrashLoopBackOff` on restore pod | PostgreSQL startup error | `kubectl logs -n cnpg-restore postgres-restore-1 --previous` for the crash reason. |
| `AccessDenied` on S3 | Wrong credentials in Secret | Re-apply the decrypted Secret; check bucket policy. |
