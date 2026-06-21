# All Buckets S3 Migration: Funnel → Traefik — COMPLETE ✅

**Date:** 2026-06-21 18:15 UTC  
**Status:** Successfully deployed  
**Buckets Migrated:** 3 (mediawiki, ghost, activitypub)

---

## Summary of Changes

| Bucket | Old URL | New URL | Status |
|---|---|---|---|
| **mediawiki** | `https://s3-1.tail477f2f.ts.net/mediawiki/` | `https://s3.tellmey.fyi/mediawiki/` | ✅ DONE (verified) |
| **ghost** | `https://s3-1.tail477f2f.ts.net/ghost/` | `https://s3.tellmey.fyi/ghost/` | ✅ DONE (env updated) |
| **activitypub** | `https://s3-1.tail477f2f.ts.net/activitypub/` | `https://s3.tellmey.fyi/activitypub/` | ✅ DONE (env updated) |

---

## Files Changed

### CORS Configuration (multi-origin support)

**`rustfs/ingress-traefik-s3.yaml`:**
- Added `https://tellmey.fyi` and `https://www.tellmey.fyi` to allowed origins

**`rustfs/nginx-s3-proxy-configmap.yaml`:**
- Changed from single origin to dynamic origin matching
- Now supports `wiki.fosscell.org`, `tellmey.fyi`, and `www.tellmey.fyi`

### Application Deployments

**`ghost/deployment.yaml`:**
- Changed `storage__s3__assetHost` from Funnel to Traefik
- Updated comment to reflect migration

**`activitypub/deployment.yaml`:**
- Changed `S3_PUBLIC_HOSTING_URL` from Funnel to Traefik

**`mediawiki/localsettings-configmap.yaml`:**
- Fixed hardcoded avatar URL (`$wgCommentsDefaultAvatar`)

---

## Verification Tests

### 1. CORS Headers ✅

```bash
# MediaWiki
$ curl -I -H "Origin: https://wiki.fosscell.org" https://s3.tellmey.fyi/mediawiki/
HTTP/2 200
access-control-allow-origin: https://wiki.fosscell.org

# Ghost
$ curl -I -H "Origin: https://tellmey.fyi" https://s3.tellmey.fyi/ghost/
HTTP/2 200
access-control-allow-origin: https://tellmey.fyi

# ActivityPub
$ curl -I -H "Origin: https://tellmey.fyi" https://s3.tellmey.fyi/activitypub/
HTTP/2 403  (empty bucket, but CORS working)
access-control-allow-origin: https://tellmey.fyi
```

**Result:** ✅ All origins now supported with dynamic CORS matching

### 2. Environment Variables ✅

```bash
# Ghost
$ kubectl exec -n ghost deploy/ghost -- printenv | grep storage__s3__assetHost
storage__s3__assetHost=https://s3.tellmey.fyi/ghost

# ActivityPub
$ kubectl exec -n ghost deploy/activitypub -- printenv | grep S3_PUBLIC_HOSTING_URL
S3_PUBLIC_HOSTING_URL=https://s3.tellmey.fyi/activitypub
```

**Result:** ✅ All applications now configured with new Traefik endpoint

### 3. Pod Health ✅

```bash
$ kubectl get pods -n ghost
NAME                          READY   STATUS    RESTARTS   AGE
activitypub-c5c7f9868-wwp7t   1/1     Running   0          5m
ghost-55c796df44-*            1/1     Running   0          2m
```

**Result:** ✅ All pods healthy and running

---

## Important Notes

### Ghost: Existing Images Still Use Old URLs

**Issue:** Ghost stores the **full assetHost URL in the database** when images are uploaded. Existing images in posts will still reference `s3-1.tail477f2f.ts.net/ghost/` until:

1. Those images are re-uploaded, OR
2. A database migration script is run to update the URLs

**Impact:** 
- ✅ New uploads will use `s3.tellmey.fyi/ghost/`
- ⚠️  Existing images in old posts still use Funnel URLs
- ✅ Both endpoints work (Funnel not removed yet)

**Options to fix existing images:**
1. **Wait** — leave Funnel active, gradually migrate as images are re-uploaded
2. **Database migration** — run SQL to update all image URLs in Ghost's `posts` and `posts_meta` tables:
   ```sql
   UPDATE posts SET mobiledoc = REPLACE(mobiledoc, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/');
   UPDATE posts SET lexical = REPLACE(lexical, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/');
   UPDATE posts_meta SET value = REPLACE(value, 'https://s3-1.tail477f2f.ts.net/ghost/', 'https://s3.tellmey.fyi/ghost/');
   ```
3. **Accept it** — both URLs work, no user impact

**Recommendation:** Option 1 (wait) is safest. Funnel will remain active for 1-2 weeks anyway.

### MediaWiki & ActivityPub: No Issues

- **MediaWiki** generates image URLs dynamically from `$wgAWSBucketDomain` → immediate switch
- **ActivityPub** generates URLs at serve time → immediate switch

---

## Performance Impact

All three services now benefit from:
- **Faster downloads** (direct to kenobi, no Tailscale relay)
- **No bandwidth limits** (Funnel has ~10 Mbps cap)
- **No timeouts** on large files

See `mediawiki-s3-test-report.md` for MediaWiki-specific benchmarks (18x faster).

---

## Monitoring Commands

```bash
# Check CORS is working for all origins
for origin in "https://wiki.fosscell.org" "https://tellmey.fyi" "https://www.tellmey.fyi"; do
  echo "Testing: $origin"
  curl -I -H "Origin: $origin" https://s3.tellmey.fyi/mediawiki/ 2>&1 | grep access-control-allow-origin
done

# Watch Traefik logs for all buckets
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail 100 -f | grep s3.tellmey.fyi

# Watch nginx S3 proxy logs
kubectl logs -n rustfs-clusters deploy/nginx-s3-proxy --tail 100 -f

# Check pod health
kubectl get pods -n mediawiki -l app.kubernetes.io/name=mediawiki
kubectl get pods -n ghost
```

---

## Next Steps

1. **Monitor for 24-48 hours** — watch for any issues
2. **Test new uploads** in Ghost — verify they use `s3.tellmey.fyi/ghost/`
3. **Optional: Database migration** for Ghost old images (after 1 week)
4. **Remove Tailscale Funnel** after 1-2 weeks of stable operation:
   ```bash
   kubectl delete ingress -n rustfs-clusters s3-funnel
   # Remove tailscale-s3-funnel.yaml from kustomization.yaml
   ```

---

## Rollback Plan (if needed)

### Quick rollback (per service):

**MediaWiki:**
```bash
kubectl edit configmap -n mediawiki mediawiki-localsettings
# Change: $wgAWSBucketDomain = 'https://s3-1.tail477f2f.ts.net/$1';
kubectl rollout restart -n mediawiki deployment/mediawiki
```

**Ghost:**
```bash
kubectl edit deployment -n ghost ghost
# Change storage__s3__assetHost back to s3-1.tail477f2f.ts.net
```

**ActivityPub:**
```bash
kubectl edit deployment -n ghost activitypub
# Change S3_PUBLIC_HOSTING_URL back to s3-1.tail477f2f.ts.net
```

---

**Migration Status:** ✅ **COMPLETE**  
**All 3 buckets migrated to Traefik (s3.tellmey.fyi)**
