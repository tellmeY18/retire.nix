# Migration: MediaWiki S3 from Tailscale Funnel → Traefik

**Goal:** Move MediaWiki's public S3 image endpoint from `https://s3-1.tail477f2f.ts.net/mediawiki/` (Tailscale Funnel) to `https://s3.kenobi.win/mediawiki/` (Traefik public ingress).

**Why:**
- Tailscale Funnel has bandwidth limits (~10 Mbps sustained, bursts higher)
- Funnel can timeout on large files or slow clients
- Traefik ingress uses kenobi's direct public IP (68.233.115.209) → no relay, better performance
- Matches the pattern used for other public services (Attic, Ghost, Answer)

**Scope:** MediaWiki only. Ghost and ActivityPub (also using Funnel for S3) are out of scope for now.

---

## Current Architecture

```
Browser (public user)
  ↓
  GET https://s3-1.tail477f2f.ts.net/mediawiki/abc/image.jpg
  Origin: https://wiki.fosscell.org
  ↓
Tailscale Funnel (edge relay, bandwidth-limited)
  ↓
s3-funnel Ingress (tailscale IngressClass)
  ↓
rustfs-s3-internal Service (ClusterIP :9000)
  ↓
nginx-s3-proxy pods (kenobi, 2 replicas)
  ↓
rustfs-chopper:9000 (primary) or rustfs-c3po:9000 (backup)
```

**Files:**
- `k8s/clusters/glug-infra/rustfs/tailscale-s3-funnel.yaml` — current Funnel ingress
- `k8s/clusters/glug-infra/rustfs/nginx-s3-proxy-configmap.yaml` — CORS headers (already set)
- `k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml` — `$wgAWSBucketDomain`

---

## Target Architecture

```
Browser (public user)
  ↓
  GET https://s3.kenobi.win/mediawiki/abc/image.jpg
  Origin: https://wiki.fosscell.org
  ↓
Traefik on kenobi (public IP 68.233.115.209, no relay)
  ↓
rustfs-s3-traefik IngressRoute (websecure :443)
  ↓
rustfs-s3-internal Service (ClusterIP :9000)  ← SAME backend
  ↓
nginx-s3-proxy pods (kenobi, 2 replicas)
  ↓
rustfs-chopper:9000 (primary) or rustfs-c3po:9000 (backup)
```

**Key insight:** The **backend stays the same** (nginx-s3-proxy → rustfs). We're only changing the **ingress layer** from Tailscale Funnel to Traefik.

---

## Prerequisites

### 1. DNS Record
Create an A record pointing `s3.kenobi.win` to kenobi's public IP:

```
s3.kenobi.win.  A  68.233.115.209
```

**Verify:**
```bash
dig +short s3.kenobi.win
# Should return: 68.233.115.209
```

### 2. Traefik ACME (Let's Encrypt)
Confirm Traefik's `letsencrypt` cert resolver is working:

```bash
kubectl get ingressroute -n ghost ghost-traefik -o yaml | grep certResolver
# Should show: certResolver: letsencrypt
```

If not set up, check `k8s/clusters/glug-infra/traefik-system/` for the Traefik Helm values.

---

## Migration Steps

### Step 1: Create Traefik IngressRoute

Create `k8s/clusters/glug-infra/rustfs/ingress-traefik-s3.yaml`:

```yaml
---
# ingress-traefik-s3.yaml — Expose RustFS S3 API publicly via Traefik.
#
# Public URL: https://s3.kenobi.win/  → direct HTTPS to the kenobi OCI VM
# (68.233.115.209), no Tailscale Funnel relay. TLS via Let's Encrypt (ACME).
#
# Security: reads are public (CORS-restricted to wiki.fosscell.org);
# writes require S3 credentials (enforced by RustFS). Traefik only provides
# the public ingress path.
#
# DNS required: s3.kenobi.win  A  68.233.115.209
---
# CORS middleware — already configured in nginx-s3-proxy ConfigMap, but
# adding here as defense-in-depth (Traefik can add CORS headers too if
# nginx is bypassed or misconfigured).
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: s3-cors
  namespace: rustfs-clusters
  labels:
    app.kubernetes.io/name: s3-public
    app.kubernetes.io/component: cors
    app.kubernetes.io/part-of: rustfs
spec:
  headers:
    accessControlAllowOriginList:
      - "https://wiki.fosscell.org"
    accessControlAllowMethods:
      - "GET"
      - "HEAD"
      - "OPTIONS"
    accessControlAllowHeaders:
      - "Range"
      - "Content-Type"
    accessControlExposeHeaders:
      - "Content-Length"
      - "Content-Range"
      - "ETag"
    accessControlMaxAge: 3600
---
# Rate limiting — prevent abuse (e.g. image scraping bots).
# Real users: 100 req/s average, burst to 200.
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: s3-rate-limit
  namespace: rustfs-clusters
  labels:
    app.kubernetes.io/name: s3-public
    app.kubernetes.io/component: rate-limit
    app.kubernetes.io/part-of: rustfs
spec:
  rateLimit:
    average: 100
    burst: 200
    period: 1s
    sourceCriterion:
      ipStrategy:
        depth: 1
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: rustfs-s3-traefik
  namespace: rustfs-clusters
  labels:
    app.kubernetes.io/name: s3-public
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: rustfs
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`s3.kenobi.win`)
      kind: Rule
      middlewares:
        - name: s3-cors
          namespace: rustfs-clusters
        - name: s3-rate-limit
          namespace: rustfs-clusters
      services:
        - name: rustfs-s3-internal
          port: 9000
  tls:
    certResolver: letsencrypt
---
# HTTP → HTTPS redirect for S3.
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: rustfs-s3-traefik-redirect
  namespace: rustfs-clusters
  labels:
    app.kubernetes.io/name: s3-public
    app.kubernetes.io/part-of: rustfs
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`s3.kenobi.win`)
      kind: Rule
      middlewares:
        - name: redirect-to-https
          namespace: traefik-system
      services:
        - name: rustfs-s3-internal
          port: 9000
```

**Apply:**
```bash
kubectl apply -f k8s/clusters/glug-infra/rustfs/ingress-traefik-s3.yaml
```

### Step 2: Update kustomization.yaml

Add the new IngressRoute to the rustfs kustomization:

```bash
# Edit k8s/clusters/glug-infra/rustfs/kustomization.yaml
# Add to resources:
#   - ingress-traefik-s3.yaml
```

### Step 3: Verify Traefik Endpoint

Wait for Let's Encrypt cert to be issued (~30s):

```bash
# Check cert is ready
kubectl get certificate -n rustfs-clusters

# Test the endpoint
curl -I https://s3.kenobi.win/mediawiki/
# Should return: HTTP/2 200 with CORS headers
```

**Full test with CORS:**
```bash
curl -I -H "Origin: https://wiki.fosscell.org" \
  https://s3.kenobi.win/mediawiki/8/8a/1st_Feb_Protest_1.jpg

# Should see:
# HTTP/2 200
# access-control-allow-origin: https://wiki.fosscell.org
# access-control-allow-methods: GET, HEAD, OPTIONS
```

### Step 4: Update MediaWiki Configuration

Edit `k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml`:

```diff
     # Public URL for images — Funnel serves this over HTTPS to the internet.
     # $1 is replaced with the bucket name.
-    $wgAWSBucketDomain = 'https://s3-1.tail477f2f.ts.net/$1';
+    $wgAWSBucketDomain = 'https://s3.kenobi.win/$1';
```

**Apply:**
```bash
kubectl apply -f k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml
```

### Step 5: Restart MediaWiki Pods

MediaWiki pods need to pick up the new LocalSettings.php:

```bash
kubectl rollout restart -n mediawiki deployment/mediawiki
kubectl rollout status -n mediawiki deployment/mediawiki
```

### Step 6: Verify Images Load

1. **Clear browser cache** (or use incognito/private window)
2. Visit https://wiki.fosscell.org (any page with images)
3. **Inspect an image URL** (right-click → "Copy Image Address"):
   - Should now be: `https://s3.kenobi.win/mediawiki/...`
   - NOT: `https://s3-1.tail477f2f.ts.net/mediawiki/...`
4. **Check browser console** — no CORS errors
5. **Test from outside tailnet** (mobile hotspot, friend's network):
   ```bash
   curl -I https://s3.kenobi.win/mediawiki/8/8a/1st_Feb_Protest_1.jpg
   # Should return HTTP/2 200
   ```

### Step 7: Monitor for 24 Hours

Watch for issues:

```bash
# Traefik access logs
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail 100 -f | grep s3.kenobi.win

# nginx S3 proxy logs
kubectl logs -n rustfs-clusters deploy/nginx-s3-proxy --tail 100 -f

# MediaWiki logs (check for S3 errors)
kubectl logs -n mediawiki deploy/mediawiki -c mediawiki --tail 50 | grep -i s3
```

**Success criteria:**
- No 404s or 5xx errors in Traefik logs for `s3.kenobi.win`
- Image load times < 2s (check browser DevTools Network tab)
- No CORS errors in browser console
- MediaWiki can upload new images (test via Special:Upload)

### Step 8: Decommission Tailscale Funnel (Optional)

Once confident the Traefik endpoint is stable (after 1-2 weeks), you can remove the Funnel ingress to reduce Tailscale API load:

```bash
# Delete the Funnel ingress
kubectl delete ingress -n rustfs-clusters s3-funnel

# Remove from kustomization.yaml
# Edit k8s/clusters/glug-infra/rustfs/kustomization.yaml
# Remove:
#   - tailscale-s3-funnel.yaml
```

**Keep `tailscale-s3-service.yaml`** (the tailnet-only LoadBalancer) — that's for internal tailnet consumers, not Funnel.

---

## Rollback Plan

If images break:

### Quick Rollback (5 minutes)

Revert MediaWiki config to use Funnel:

```bash
# Edit localsettings-configmap.yaml
# Change back to: $wgAWSBucketDomain = 'https://s3-1.tail477f2f.ts.net/$1';

kubectl apply -f k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml
kubectl rollout restart -n mediawiki deployment/mediawiki
```

### Full Rollback (if Traefik is broken)

```bash
# Delete Traefik IngressRoute
kubectl delete -f k8s/clusters/glug-infra/rustfs/ingress-traefik-s3.yaml

# Revert MediaWiki config (as above)
```

The Funnel ingress stays in place during the migration, so it's still serving traffic until you explicitly delete it in Step 8.

---

## Performance Comparison

After migration, compare image load times:

**Before (Funnel):**
```bash
time curl -o /dev/null https://s3-1.tail477f2f.ts.net/mediawiki/8/8a/1st_Feb_Protest_1.jpg
```

**After (Traefik):**
```bash
time curl -o /dev/null https://s3.kenobi.win/mediawiki/8/8a/1st_Feb_Protest_1.jpg
```

Expected improvement: **2-5x faster** for users geographically close to kenobi's OCI region (Phoenix, AZ). Users far from Phoenix may see minimal difference.

---

## Files Summary

| File | Action | Description |
|---|---|---|
| `rustfs/ingress-traefik-s3.yaml` | **CREATE** | Traefik IngressRoute for s3.kenobi.win |
| `rustfs/kustomization.yaml` | **EDIT** | Add ingress-traefik-s3.yaml to resources |
| `mediawiki/localsettings-configmap.yaml` | **EDIT** | Change `$wgAWSBucketDomain` to s3.kenobi.win |
| `rustfs/tailscale-s3-funnel.yaml` | **DELETE (later)** | Remove after 1-2 weeks of stable Traefik |
| `rustfs/nginx-s3-proxy-configmap.yaml` | No change | CORS already configured |

---

## Testing Checklist

- [ ] DNS `s3.kenobi.win` resolves to 68.233.115.209
- [ ] Traefik IngressRoute created and cert issued
- [ ] `curl https://s3.kenobi.win/mediawiki/` returns HTTP 200
- [ ] CORS headers present (`access-control-allow-origin: https://wiki.fosscell.org`)
- [ ] MediaWiki config updated to new URL
- [ ] MediaWiki pods restarted
- [ ] Browser DevTools shows images loading from s3.kenobi.win
- [ ] No CORS errors in browser console
- [ ] Test upload: Special:Upload on wiki works
- [ ] Test from outside tailnet (mobile hotspot)
- [ ] Monitor logs for 24h (no errors)
- [ ] Performance comparison (Funnel vs Traefik)

---

## Notes

- **Ghost and ActivityPub** also use Funnel for S3 (`https://s3-1.tail477f2f.ts.net/ghost` and `/activitypub`). They are **out of scope** for now. If this migration goes well, we can replicate it for them later.
- **CORS is configured in TWO places** (nginx ConfigMap + Traefik Middleware) for defense-in-depth. If nginx fails to add headers, Traefik's middleware will catch it.
- **Rate limiting** is set generously (100 req/s avg, 200 burst). Adjust if you see legitimate traffic getting throttled.

---

**Status:** PLANNED. Ready to execute.
