# FOSS Cell Wiki Access — Browser Extension

A WebExtensions (Manifest V3) browser extension that appends the community
member token to every request to `wiki.fosscell.org`. Traefik recognises the
token and routes matching requests directly to the wiki backend, bypassing the
Anubis proof-of-work challenge entirely.

## Files

| File | Purpose |
|---|---|
| `manifest.json` | Extension manifest (MV3, cross-browser) |
| `background.js` | Service worker — installs the `declarativeNetRequest` rule |
| `popup.html` / `popup.js` | Toolbar popup showing active status |

## Token rotation

1. Generate a new token: `openssl rand -hex 24`
2. Update `TOKEN` in `background.js` and `popup.js`
3. Update `FOSSCellWiki/token=` in:
   - `k8s/clusters/glug-infra/mediawiki/ingress-traefik.yaml` (Traefik HeaderRegexp)
   - `k8s/clusters/glug-infra/traefik/anubis.yaml` (Anubis ALLOW rule)
4. Apply: `kubectl apply -f ...` for both files, then `kubectl rollout restart deployment/anubis -n traefik-system`
5. Bump `version` in `manifest.json` and redistribute the extension

## Building a distributable zip

```sh
cd k8s/apps/wiki-access-extension
zip -r fosscell-wiki-access.zip manifest.json background.js popup.html popup.js
```

Load the `.zip` in Chrome as an unpacked extension, or sign it as an `.xpi` for Firefox.
