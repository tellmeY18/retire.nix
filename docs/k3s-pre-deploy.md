# k3s + CNPG — Pre-Deploy Checklist

This document is a **run-once** checklist to verify everything is in place
before the first `just k8s::apply`. Each section has verification commands
that should pass before moving to the next.

> After a successful first deploy, day-2 operations are covered in
> [`k3s-cnpg.md`](./k3s-cnpg.md) and the [runbooks](../k8s/docs/runbooks/).

---

## 0. Legend

```
[ ] — action item (do this)
🔍  — verification command (run this, check output)
```

---

## 1. NixOS host is deployed and healthy

The k3s module, sops secrets, and ZFS datasets must be active on chopper
before any k8s resources can be applied.

### 1.1 Rebuild chopper with latest config

```sh
# From your admin machine (laptop):
nh os switch            # or: nixos-rebuild switch --flake .#chopper
```

### 1.2 Verify k3s is running

```sh
🔍 systemctl status k3s
# Expected: active (running)

🔍 kubectl get nodes
# Expected: chopper   Ready   control-plane,master   ...
```

If `kubectl` fails with permission denied:

```sh
# Ensure KUBECONFIG is set (profiles/k3s-node.nix exports this)
🔍 echo $KUBECONFIG
# Expected: /etc/rancher/k3s/k3s.yaml

# Verify your user is in the wheel group (k3s.yaml is mode 0640 root:wheel)
🔍 id | grep wheel
```

### 1.3 Verify sops secrets are decrypted

```sh
🔍 ls /run/secrets/k3s-token
# Expected: file exists

🔍 ls /run/secrets/tailscale-operator-client-id
🔍 ls /run/secrets/tailscale-operator-client-secret
# Expected: both files exist
```

If missing, check `sops-nix` activation:

```sh
🔍 systemctl status sops-nix
🔍 journalctl -u sops-nix --no-pager | tail -20
```

### 1.4 Verify ZFS dataset for OpenEBS

The `rpool/openebs` dataset must exist — k3s/OpenEBS will NOT create it.

```sh
🔍 zfs list rpool/openebs
# Expected: shows the dataset (any size is fine — PVs are carved from it)
```

If it doesn't exist, create it:

```sh
[ ] sudo zfs create -o mountpoint=none -o recordsize=8K \
      -o logbias=throughput -o compression=zstd -o xattr=sa \
      rpool/openebs
```

Verify properties:

```sh
🔍 zfs get recordsize,compression,logbias rpool/openebs
# Expected: recordsize=8K, compression=zstd, logbias=throughput
```

---

## 2. Tailscale prerequisites

All cluster traffic (k3s, etcd, kubectl, pg-rw endpoint) rides the tailnet.
These must be configured in the **Tailscale admin console** before deploy.

### 2.1 Tailscale is running and connected

```sh
🔍 systemctl status tailscaled
# Expected: active (running)

🔍 tailscale status --self
# Expected: shows chopper's Tailscale IP (100.x.y.z), status "active"
```

### 2.2 Verify the node IP matches config

```sh
🔍 tailscale ip -4
# Expected: 100.107.213.17 (must match nodeIP in hosts/chopper/parts/k3s.nix)
```

If the IP changed (e.g., after re-auth), update `hosts/chopper/parts/k3s.nix`
and rebuild.

### 2.3 ACL tags configured

In [Tailscale Admin → ACLs](https://login.tailscale.com/admin/acls), verify:

```
[ ] tagOwners includes: tag:k8s, tag:k8s-operator, tag:server
[ ] ACL rule: tag:k8s → tag:k8s:5432 (webservices reach Postgres)
[ ] ACL rule: tag:server → tag:server:* (k3s inter-node)
[ ] ACL rule: autogroup:admin → tag:server:* (laptop admin access)
```

See [docs/k3s-cnpg.md § 10](./k3s-cnpg.md#10-tailscale-acl-requirements)
for the full JSON.

### 2.4 OAuth client configured

In [Tailscale Admin → Settings → OAuth](https://login.tailscale.com/admin/settings/oauth):

```
[ ] OAuth client exists with:
    - Scope: devices → Write
    - Scope: auth_keys → Write
    - Tags: tag:k8s is ticked ← most common gotcha!
[ ] Client ID and Secret are stored in secrets/chopper/secrets.yaml
    under keys: tailscale-operator-client-id, tailscale-operator-client-secret
```

Verify the sops-encrypted values are populated (not empty strings):

```sh
🔍 sops --decrypt secrets/chopper/secrets.yaml | grep -A1 tailscale-operator
# Expected: non-empty client-id and client-secret values
```

### 2.5 MagicDNS enabled

```
[ ] MagicDNS is ON in Tailscale Admin → DNS
```

Without this, `pg-rw.<tailnet>.ts.net` won't resolve.

---

## 3. Bootstrap operators are healthy

These are deployed by NixOS (via `services.k3s.manifests`) the moment k3s
starts. They must be running before helmfile can deploy workloads.

### 3.1 OpenEBS ZFS LocalPV CSI driver

```sh
🔍 kubectl -n openebs get pods
# Expected: openebs-zfs-controller-0   Running
#           openebs-zfs-node-xxxxx     Running

🔍 kubectl get storageclass zfs-localpv
# Expected: zfs-localpv (default)   zfs.csi.openebs.io   ...
```

If pods are not running, check the HelmChart job:

```sh
🔍 kubectl -n kube-system get jobs | grep openebs
🔍 kubectl -n kube-system logs job/helm-install-openebs-zfs-localpv
```

### 3.2 Tailscale Kubernetes operator

```sh
🔍 kubectl -n tailscale get pods
# Expected: operator-xxxxx   Running
#           (possibly a proxies-xxxxx pod too once services are created)

🔍 kubectl -n tailscale logs deploy/operator --tail=20
# Expected: no "fatal" or "requested tags ... are invalid" errors
```

Common failure: OAuth credentials are wrong or `tag:k8s` isn't ticked on the
OAuth client. Fix by editing the sops secret and rebuilding:

```sh
sops secrets/chopper/secrets.yaml   # fix client-id / client-secret
nh os switch                        # re-materialises the k8s Secret
kubectl -n tailscale rollout restart deploy/operator
```

### 3.3 The operator-oauth Secret exists in-cluster

```sh
🔍 kubectl -n tailscale get secret operator-oauth
# Expected: shows the secret (created by k3s-tailscale-oauth-secret oneshot)
```

---

## 4. Secrets (Tier 2) can be decrypted

The laptop (or chopper itself) must be able to decrypt the helm values secrets
used by helmfile.

### 4.1 Verify sops can decrypt cluster-side secrets

```sh
🔍 sops --decrypt k8s/apps/postgres/secrets.yaml > /dev/null && echo OK
# Expected: OK

🔍 sops --decrypt k8s/apps/cnpg-operator/secrets.yaml > /dev/null && echo OK
# Expected: OK
```

### 4.2 Verify S3 backup credentials are real (not placeholders)

```sh
🔍 sops --decrypt k8s/apps/postgres/secrets.yaml | grep -E "bucket|endpoint|accessKey|secretKey"
# Expected: all four have non-empty values (not "" or PLACEHOLDER)
```

### 4.3 Verify helm-secrets integration works end-to-end

```sh
🔍 just k8s::template > /dev/null && echo OK
# Expected: OK (helmfile renders without errors)
```

---

## 5. External dependencies

### 5.1 S3-compatible bucket exists

The bucket referenced in `k8s/apps/postgres/secrets.yaml` must already exist
at the provider (Cloudflare R2, Backblaze B2, AWS S3, etc.):

```
[ ] Bucket is created at the provider
[ ] Access key has read/write permission on that bucket
[ ] Endpoint URL is correct for the region/provider
```

You can verify connectivity from chopper (if `aws` CLI or `s3cmd` is available):

```sh
# Example for R2 / S3-compatible:
🔍 AWS_ACCESS_KEY_ID=<key> AWS_SECRET_ACCESS_KEY=<secret> \
   aws --endpoint-url <endpoint> s3 ls s3://<bucket>/ 2>&1
# Expected: empty listing (new bucket) or existing backup objects
```

### 5.2 kubectl-cnpg plugin (optional but recommended)

```sh
🔍 kubectl cnpg version
# Expected: shows version, or "command not found" → install it:
#   kubectl krew install cnpg
```

---

## 6. Deploy!

Once all checks above pass:

```sh
# Preview what will be applied (safe — no mutations):
just k8s::diff

# Apply for real:
just k8s::apply
```

`just k8s::apply` does:
1. `helmfile sync` → installs CNPG operator (cnpg-system) → then Postgres
   cluster (cnpg-clusters) with helm-secrets decrypting S3 creds inline.
2. `kubectl apply -k clusters/glug-infra` → namespace + NetworkPolicies +
   Tailscale LoadBalancer Service.

---

## 7. Post-deploy verification

Run these after `just k8s::apply` returns successfully. The Postgres cluster
takes 2–5 minutes to fully bootstrap (init containers, WAL setup, streaming
replication sync).

### 7.1 CNPG operator is running

```sh
🔍 kubectl -n cnpg-system get pods
# Expected: 1/1 Running

🔍 kubectl get crd | grep cnpg
# Expected: clusters.postgresql.cnpg.io, poolers.postgresql.cnpg.io,
#           backups.postgresql.cnpg.io, scheduledbackups.postgresql.cnpg.io
```

### 7.2 Postgres cluster is healthy

```sh
🔍 just k8s::cnpg-status
# Expected: "Cluster in healthy state"
#           Instances: 3, Ready: 3
#           Primary: postgres-1 (or whichever)

🔍 kubectl -n cnpg-clusters get pods -l cnpg.io/cluster=postgres
# Expected: 3 pods, all 1/1 Running
```

### 7.3 Replication is streaming

```sh
🔍 kubectl -n cnpg-clusters exec -it postgres-1 -- \
    psql -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
# Expected: 2 rows, state=streaming, sync_state includes "sync" or "quorum"
```

### 7.4 PgBouncer pooler is up

```sh
🔍 kubectl -n cnpg-clusters get pods -l cnpg.io/poolerName=postgres-pooler-rw
# Expected: 2 pods Running
```

### 7.5 Tailscale endpoint is registered

```sh
🔍 kubectl -n cnpg-clusters get svc postgres-pooler-rw-tailscale
# or:
🔍 kubectl -n cnpg-clusters get svc -l tailscale.com/hostname=pg-rw
# Expected: TYPE=LoadBalancer, EXTERNAL-IP shows a tailscale IP

🔍 tailscale status | grep pg-rw
# Expected: pg-rw   100.x.y.z   ...   tag:k8s
```

### 7.6 WAL archiving is active

```sh
🔍 kubectl -n cnpg-clusters exec -it postgres-1 -- \
    psql -c "SELECT last_archived_wal, last_failed_wal FROM pg_stat_archiver;"
# Expected: last_archived_wal is non-null; last_failed_wal is empty/null
```

### 7.7 Trigger a test backup

```sh
just k8s::cnpg-backup-now

# Wait ~30s, then:
🔍 just k8s::cnpg-backup-list
# Expected: one Backup with PHASE=completed
```

### 7.8 Connect from a tailnet client

From any machine on the tailnet (laptop, cloud VM, etc.):

```sh
# Get the app password:
APP_PASS=$(kubectl -n cnpg-clusters get secret postgres-app \
  -o jsonpath='{.data.password}' | base64 -d)

🔍 psql "postgres://app:${APP_PASS}@pg-rw.<tailnet>.ts.net:5432/app" \
    -c "SELECT 1;"
# Expected: returns 1
```

Replace `<tailnet>` with your actual tailnet domain (e.g., `tail1234.ts.net`).

---

## Troubleshooting quick-reference

| Symptom | Likely cause | Fix |
|---|---|---|
| `kubectl: connection refused` | k3s not running or KUBECONFIG wrong | `systemctl restart k3s`, check `$KUBECONFIG` |
| OpenEBS pods `Pending` | `rpool/openebs` dataset missing | Create it (step 1.4) |
| Tailscale operator crash-loops | OAuth creds wrong or `tag:k8s` not ticked | Fix OAuth client, update sops secret, rebuild |
| `pg-rw` not in `tailscale status` | Tailscale operator can't register device | Check operator logs, verify ACLs + OAuth tags |
| Postgres pods `Pending` | StorageClass missing or PVC can't bind | Verify `kubectl get sc`, check OpenEBS controller logs |
| Backup PHASE=failed | S3 creds wrong or bucket doesn't exist | Decrypt secrets, verify endpoint/bucket/keys |
| Replication lag growing | Disk I/O saturated (old laptop) | Check `iostat`, consider reducing `max_wal_size` |
| `helm secrets decrypt` fails | Plugin version mismatch | Rebuild home-manager (uses `wrapHelm` now) |
| helmfile "file does not exist" | Old manual helm-secrets plugin still in `~/.local/share/helm/plugins/` | `rm -rf ~/.local/share/helm/plugins/helm-secrets` |

---

## Summary of prerequisites

| # | What | How to verify | Done? |
|---|---|---|---|
| 1 | NixOS rebuilt with k3s config | `systemctl status k3s` → active | ☐ |
| 2 | `rpool/openebs` ZFS dataset | `zfs list rpool/openebs` | ☐ |
| 3 | sops secrets decrypted on host | `ls /run/secrets/k3s-token` | ☐ |
| 4 | Tailscale connected | `tailscale status --self` → active | ☐ |
| 5 | Tailscale ACLs configured | Admin console: tags + rules | ☐ |
| 6 | Tailscale OAuth client | scopes + `tag:k8s` ticked | ☐ |
| 7 | MagicDNS enabled | Admin console → DNS | ☐ |
| 8 | OpenEBS CSI running | `kubectl -n openebs get pods` → Running | ☐ |
| 9 | Tailscale operator running | `kubectl -n tailscale get pods` → Running | ☐ |
| 10 | S3 bucket exists | Provider console or `aws s3 ls` | ☐ |
| 11 | Secrets decrypt OK | `just k8s::template` succeeds | ☐ |
| 12 | Old helm-secrets plugin removed | `ls ~/.local/share/helm/plugins/` empty | ☐ |
