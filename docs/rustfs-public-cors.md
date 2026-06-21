# RustFS Public S3 Endpoint — CORS Configuration

**Problem:** MediaWiki users outside the tailnet couldn't see images because browsers blocked cross-origin requests from `https://wiki.fosscell.org` to `https://s3-1.tail477f2f.ts.net` due to missing CORS headers.

**Solution:** CORS headers are now configured in the nginx S3 failover proxy.

---

## Architecture

```
Browser (outside tailnet)
  ↓
  GET https://s3-1.tail477f2f.ts.net/mediawiki/abc/image.jpg
  Origin: https://wiki.fosscell.org
  ↓
Tailscale Funnel (s3-1.tail477f2f.ts.net)
  ↓
nginx-s3-proxy (k8s/rustfs-clusters)
  ← adds CORS headers here
  ↓
rustfs-chopper or rustfs-c3po (failover)
```

## CORS Headers Set

The nginx proxy adds these headers to **all** responses:

```nginx
Access-Control-Allow-Origin: https://wiki.fosscell.org
Access-Control-Allow-Methods: GET, HEAD, OPTIONS
Access-Control-Allow-Headers: Range, Content-Type
Access-Control-Expose-Headers: Content-Length, Content-Range, ETag
Access-Control-Max-Age: 3600
```

### Why These Headers?

- `Allow-Origin: wiki.fosscell.org` — only the wiki can embed these images (prevents hotlinking abuse)
- `Allow-Methods: GET, HEAD, OPTIONS` — read-only operations (no PUT/DELETE from browsers)
- `Allow-Headers: Range, Content-Type` — supports partial content requests (video streaming, resume downloads)
- `Expose-Headers: Content-Length, ...` — lets browsers read file metadata for progress bars
- `Max-Age: 3600` — cache the preflight response for 1 hour

## Testing CORS

```bash
# Verify CORS headers are sent
curl -I -H "Origin: https://wiki.fosscell.org" \
  https://s3-1.tail477f2f.ts.net/mediawiki/8/8a/1st_Feb_Protest_1.jpg

# Should see:
# access-control-allow-origin: https://wiki.fosscell.org

# Test preflight (OPTIONS request)
curl -I -X OPTIONS \
  -H "Origin: https://wiki.fosscell.org" \
  -H "Access-Control-Request-Method: GET" \
  https://s3-1.tail477f2f.ts.net/mediawiki/test.jpg

# Should return HTTP 204 with CORS headers
```

## Files

- `k8s/clusters/glug-infra/rustfs/nginx-s3-proxy-configmap.yaml` — CORS config
- `k8s/clusters/glug-infra/rustfs/tailscale-s3-funnel.yaml` — public endpoint
- `k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml` — `$wgAWSBucketDomain`

## Applying Changes

```bash
# Update ConfigMap
kubectl apply -f k8s/clusters/glug-infra/rustfs/nginx-s3-proxy-configmap.yaml

# Restart nginx to pick up new config
kubectl rollout restart -n rustfs-clusters deployment/nginx-s3-proxy
kubectl rollout status -n rustfs-clusters deployment/nginx-s3-proxy
```

## Alternative: Traefik Public Ingress

Tailscale Funnel has bandwidth limits and can timeout on large files. For production, consider adding a Traefik IngressRoute (like Attic's `cache.tellmey.fyi`) that exposes the S3 endpoint via the kenobi OCI VM's public IP.

**Draft Traefik config** (not yet implemented):

```yaml
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: rustfs-s3-public
  namespace: rustfs-clusters
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`s3.kenobi.win`)
      kind: Rule
      middlewares:
        - name: s3-cors
          namespace: rustfs-clusters
      services:
        - name: rustfs-s3-internal
          port: 9000
  tls:
    certResolver: letsencrypt
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: s3-cors
  namespace: rustfs-clusters
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
```

Then update MediaWiki's `$wgAWSBucketDomain` to `https://s3.kenobi.win/$1`.

## Troubleshooting

### Images still don't load?

1. Check browser console for CORS errors
2. Verify the Origin header matches:
   ```bash
   # From the wiki server
   curl -I -H "Origin: https://wiki.fosscell.org" https://s3-1.tail477f2f.ts.net/mediawiki/test.jpg
   ```
3. Check nginx logs:
   ```bash
   kubectl logs -n rustfs-clusters deploy/nginx-s3-proxy --tail 50
   ```

### CORS headers not appearing?

1. Verify ConfigMap was updated:
   ```bash
   kubectl get cm -n rustfs-clusters nginx-s3-proxy -o yaml | grep -A5 "Access-Control"
   ```
2. Confirm nginx pods picked up the new config:
   ```bash
   kubectl exec -n rustfs-clusters deploy/nginx-s3-proxy -- cat /etc/nginx/conf.d/default.conf
   ```
3. Force a pod restart if needed:
   ```bash
   kubectl delete pod -n rustfs-clusters -l app.kubernetes.io/name=s3-failover
   ```

---

**Status:** ✅ Deployed as of 2026-06-21. MediaWiki images are now accessible to public users.
