# Wikipedia Mobile App Support — Setup Guide

**Status:** PLANNED (ready to deploy)  
**Purpose:** Enable the Wikipedia mobile app to connect to wiki.fosscell.org

---

## What is mobileapps?

The Wikimedia `mobileapps` service provides structured REST API endpoints that mobile apps (Wikipedia iOS/Android) use to fetch page content, summaries, and metadata. It sits between the app and MediaWiki, transforming wikitext/HTML into mobile-friendly JSON.

---

## Architecture

```
Wikipedia Mobile App (iOS/Android)
  ↓
  GET https://wiki.fosscell.org/api/rest_v1/page/summary/Main_Page
  ↓
Traefik IngressRoute (PathPrefix: /api/rest_v1/)
  ↓
mobileapps Node.js service (port 8888)
  ↓ fetches from:
  - wiki.fosscell.org/api.php (MediaWiki API)
  - wiki.fosscell.org/api/rest_v1/ (Parsoid for HTML)
```

**Key insight:** mobileapps is a **stateless Node.js service** (no database) that proxies/transforms requests to your existing MediaWiki instance.

---

## Files Created

| File | Purpose |
|---|---|
| `mobileapps/Dockerfile` | Builds image from wikimedia/mediawiki-services-mobileapps |
| `mobileapps/configmap.yaml` | Config pointing at wiki.fosscell.org |
| `mobileapps/deployment.yaml` | 2-replica stateless deployment |
| `mobileapps/ingress-traefik.yaml` | Routes /api/rest_v1/ to the service |
| `mobileapps/kustomization.yaml` | Kustomize entry point |
| `.github/workflows/build-mobileapps.yml` | GitHub Actions to build the image |

---

## Deployment Steps

### Step 1: Build the Docker Image

The Dockerfile clones Wikimedia's mobileapps repo and runs `npm install`. Build it via GitHub Actions:

```bash
# Commit and push the Dockerfile
git add k8s/clusters/glug-infra/mobileapps/
git add .github/workflows/build-mobileapps.yml
git commit -m "Add mobileapps service for Wikipedia mobile app support"
git push

# Trigger the workflow manually (or push will auto-trigger)
# Go to Actions tab → "Build mobileapps" → Run workflow
```

Wait for the image to be available at `ghcr.io/tellmey18/mobileapps:latest`.

### Step 2: Deploy to k8s

```bash
kubectl apply -k k8s/clusters/glug-infra/mobileapps/

# Verify pods are running
kubectl get pods -n mobileapps

# Check logs
kubectl logs -n mobileapps -l app.kubernetes.io/name=mobileapps --tail 50
```

### Step 3: Test the API

```bash
# Test the /_info endpoint (health check)
curl https://wiki.fosscell.org/api/rest_v1/_info

# Test page summary
curl https://wiki.fosscell.org/api/rest_v1/page/summary/Main_Page

# Should return JSON with:
# - extract: short summary
# - thumbnail: featured image
# - originalimage: full-size image
```

### Step 4: Configure the Wikipedia App

On the Wikipedia mobile app (iOS/Android):

1. **Open Settings** → **Add Account** or **Custom Wiki**
2. **Enter URL:** `https://wiki.fosscell.org`
3. **The app will auto-discover** the `/api/rest_v1/` endpoints

The app expects these endpoints:
- `/api/rest_v1/page/summary/{title}` — page summaries
- `/api/rest_v1/page/mobile-html/{title}` — mobile-optimized HTML
- `/api/rest_v1/page/media-list/{title}` — media gallery

---

## Configuration Details

### ConfigMap — Points at Your Wiki

```yaml
mobileapps_uri: https://wiki.fosscell.org
mobile_html_rest_api_base_uri: https://wiki.fosscell.org/api/
parsoid_uri: https://wiki.fosscell.org/api/rest_v1/
```

### Content Security Policy (CSP)

Adjusted to allow resources from your domains:

```yaml
connect-src https://wiki.fosscell.org https://s3.tellmey.fyi 'self';
media-src https://s3.tellmey.fyi https://wiki.fosscell.org 'self';
img-src https://s3.tellmey.fyi https://wiki.fosscell.org 'self' data:;
```

### Traefik Route

```yaml
match: Host(`wiki.fosscell.org`) && PathPrefix(`/api/rest_v1/`)
```

**Important:** This intercepts `/api/rest_v1/` **before** it reaches MediaWiki. Traefik priority ensures mobileapps handles it, not MediaWiki's built-in REST API.

---

## Troubleshooting

### Issue: "Cannot reach wiki"

**Check:**
1. mobileapps pods are running:
   ```bash
   kubectl get pods -n mobileapps
   ```
2. Traefik route is active:
   ```bash
   kubectl get ingressroute -n mobileapps mobileapps-traefik
   ```
3. Test the endpoint directly:
   ```bash
   curl https://wiki.fosscell.org/api/rest_v1/_info
   ```

### Issue: "Page not found" or 404

**Check:**
- MediaWiki's Parsoid is enabled (it should be, you have VisualEditor working)
- Test Parsoid directly:
  ```bash
  curl https://wiki.fosscell.org/api/rest_v1/page/html/Main_Page
  ```

### Issue: Images don't load in app

**Check CSP headers:**
```bash
curl -I https://wiki.fosscell.org/api/rest_v1/page/summary/Main_Page | grep content-security-policy
```

Should allow `https://s3.tellmey.fyi` for images.

---

## Resource Usage

- **CPU:** 50m request, 500m limit
- **Memory:** 128Mi request, 512Mi limit
- **Replicas:** 2 (stateless, can scale horizontally)
- **No persistent storage needed**

---

## Maintenance

### Update mobileapps

To pull the latest version from Wikimedia:

```bash
# Rebuild the Docker image (GitHub Actions workflow)
# Or manually:
docker build -t ghcr.io/tellmey18/mobileapps:latest \
  k8s/clusters/glug-infra/mobileapps/

docker push ghcr.io/tellmey18/mobileapps:latest

# Restart deployment
kubectl rollout restart -n mobileapps deployment/mobileapps
```

### Monitor

```bash
# Logs
kubectl logs -n mobileapps -l app.kubernetes.io/name=mobileapps --tail 100 -f

# Metrics
kubectl top pod -n mobileapps
```

---

## Alternative: Use MediaWiki's Built-in REST API

MediaWiki 1.35+ includes a basic REST API at `/api/rest_v1/`. However, it's **less feature-rich** than Wikimedia's mobileapps service:

| Feature | MediaWiki Built-in | mobileapps Service |
|---|---|---|
| Page summaries | ❌ Limited | ✅ Full |
| Mobile-optimized HTML | ✅ Basic | ✅ Optimized |
| Media lists | ❌ | ✅ |
| Wikipedia app support | ⚠️ Partial | ✅ Full |

If you only need basic Wikipedia app support, you *might* get away without mobileapps. But for the full experience (images, summaries, media galleries), the dedicated service is recommended.

---

## Testing Checklist

- [ ] Build Docker image successfully
- [ ] Deploy to k8s, pods running
- [ ] `curl https://wiki.fosscell.org/api/rest_v1/_info` returns JSON
- [ ] `curl https://wiki.fosscell.org/api/rest_v1/page/summary/Main_Page` returns summary
- [ ] Wikipedia app connects to `https://wiki.fosscell.org`
- [ ] App can load pages, images display correctly
- [ ] No CORS errors in app logs

---

**Status:** Ready to deploy once Docker image is built.  
**Estimated setup time:** 30 minutes (mostly waiting for Docker build)
