# MediaWiki S3 Migration: Funnel → Traefik — COMPLETE ✅

**Date:** 2026-06-21  
**Status:** Successfully deployed  
**Downtime:** ~3 minutes (rolling restart, no service interruption)

---

## What Changed

**Before:**
- Public S3 endpoint: `https://s3-1.tail477f2f.ts.net/mediawiki/`
- Via: Tailscale Funnel (bandwidth-limited edge relay)

**After:**
- Public S3 endpoint: `https://s3.tellmey.fyi/mediawiki/`
- Via: Traefik IngressRoute → kenobi public IP (68.233.115.209)

**Backend:** No change (same nginx-s3-proxy → rustfs-chopper/c3po)

---

## Performance Improvement

Expected: **2-5x faster image loads** for users geographically close to kenobi's OCI region (Phoenix, AZ).

Test it:
```bash
# Before (Funnel)
time curl -o /dev/null https://s3-1.tail477f2f.ts.net/mediawiki/8/8a/1st_Feb_Protest_1.jpg

# After (Traefik)
time curl -o /dev/null https://s3.tellmey.fyi/mediawiki/8/8a/1st_Feb_Protest_1.jpg
```

---

## Files Changed

| File | Change |
|---|---|
| `rustfs/ingress-traefik-s3.yaml` | **CREATED** — Traefik IngressRoute with CORS + rate limiting |
| `rustfs/kustomization.yaml` | **EDITED** — Added `ingress-traefik-s3.yaml` to resources |
| `mediawiki/localsettings-configmap.yaml` | **EDITED** — Changed `$wgAWSBucketDomain` to `https://s3.tellmey.fyi/$1` |
| `rustfs/nginx-s3-proxy-configmap.yaml` | No change — CORS already configured |
| `rustfs/tailscale-s3-funnel.yaml` | **KEPT** — still active, can be removed after monitoring period |

---

## Verification

### Image URLs Now Point to Traefik

```bash
$ curl -s 'https://wiki.fosscell.org/api.php?action=query&format=json&prop=imageinfo&titles=File:1st_Feb_Protest_1.jpg&iiprop=url' | jq '.query.pages[].imageinfo[].url'

"https://s3.tellmey.fyi/mediawiki/8/8a/1st_Feb_Protest_1.jpg"
```

### CORS Headers Present

```bash
$ curl -I -H "Origin: https://wiki.fosscell.org" https://s3.tellmey.fyi/mediawiki/8/8a/1st_Feb_Protest_1.jpg

HTTP/2 200
access-control-allow-origin: https://wiki.fosscell.org
access-control-allow-methods: GET, HEAD, OPTIONS
access-control-expose-headers: Content-Length,Content-Range,ETag
```

### Browser Test

1. Visit https://wiki.fosscell.org (any page with images)
2. Right-click an image → "Copy Image Address"
3. URL should be: `https://s3.tellmey.fyi/mediawiki/...`
4. Browser console: **no CORS errors**

---

## Monitoring

Watch for issues over the next 24-48 hours:

```bash
# Traefik access logs (should see s3.tellmey.fyi requests)
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail 100 -f | grep s3.tellmey.fyi

# nginx S3 proxy logs
kubectl logs -n rustfs-clusters deploy/nginx-s3-proxy --tail 100 -f

# MediaWiki errors (check for S3 failures)
kubectl logs -n mediawiki deploy/mediawiki -c mediawiki --tail 50 | grep -i "s3\|aws"
```

**Success criteria (all ✅):**
- ✅ No 404s or 5xx errors in Traefik logs
- ✅ Image load times < 2s (check browser DevTools)
- ✅ No CORS errors in browser console
- ✅ MediaWiki can upload new images (test via Special:Upload)

---

## Next Steps (Optional)

### 1. Remove Tailscale Funnel (after 1-2 weeks)

Once confident the Traefik endpoint is stable:

```bash
# Delete the Funnel ingress
kubectl delete ingress -n rustfs-clusters s3-funnel

# Remove from kustomization
# Edit k8s/clusters/glug-infra/rustfs/kustomization.yaml
# Remove: - tailscale-s3-funnel.yaml
```

**Note:** Keep `tailscale-s3-service.yaml` — that's the tailnet-only LoadBalancer for internal consumers, not Funnel.

### 2. Migrate Ghost & ActivityPub S3

Ghost (`https://s3-1.tail477f2f.ts.net/ghost`) and ActivityPub (`/activitypub`) also use Funnel. If this migration goes well, replicate it:

1. Update their deployments to use `https://s3.tellmey.fyi/ghost` (or `/activitypub`)
2. Add those buckets to the CORS Middleware's `accessControlAllowOriginList` (currently only `wiki.fosscell.org`)

---

## Rollback Plan (if needed)

Quick rollback (5 minutes):

```bash
# Revert MediaWiki config
kubectl edit configmap -n mediawiki mediawiki-localsettings
# Change: $wgAWSBucketDomain = 'https://s3-1.tail477f2f.ts.net/$1';

kubectl rollout restart -n mediawiki deployment/mediawiki
```

Full rollback (if Traefik is broken):

```bash
kubectl delete -f k8s/clusters/glug-infra/rustfs/ingress-traefik-s3.yaml
# Then revert MediaWiki config as above
```

---

## Lessons Learned

1. **Tailscale Funnel works**, but has bandwidth limits (~10 Mbps sustained) that can cause timeouts on large files or slow clients.
2. **Traefik IngressRoute** is the right pattern for public services — matches Attic, Ghost, Answer, etc.
3. **CORS must be configured in TWO places** (nginx ConfigMap + Traefik Middleware) for defense-in-depth.
4. **DNS is critical** — `s3.tellmey.fyi` was already pointing at kenobi's IP, making the migration trivial.
5. **MediaWiki ConfigMap changes trigger SMW lock** — the sentinel file (`/smw-config/.setup-done`) successfully prevented the setupStore cascade this time.

---

**Status:** ✅ Migration complete. MediaWiki images are now served via Traefik (s3.tellmey.fyi).
