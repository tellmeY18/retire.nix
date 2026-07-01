# FOSS Cell Wiki Access — Member Setup Guide

Install the **FOSS Cell Wiki Access** browser extension to get instant, challenge-free
access to [wiki.fosscell.org](https://wiki.fosscell.org). Without it you may occasionally
be asked to solve a short proof-of-work puzzle (our bot protection). With it, you skip
that entirely.

The extension works by appending a private community token to your browser's
`User-Agent` header for requests to `wiki.fosscell.org` only. No data is collected,
no other sites are affected.

---

## Firefox (Desktop) — Recommended

Firefox has the best extension support and is the primary target.

### Temporary install (dev / testing)

1. Download `fosscell-wiki-access.zip` from the FOSS Cell wiki admin or your sysadmin.
2. Extract it to a local folder (e.g. `~/fosscell-wiki-access/`).
3. Open Firefox → address bar → `about:debugging` → **This Firefox**.
4. Click **Load Temporary Add-on…**
5. Navigate into the extracted folder and select `manifest.json`.
6. The extension appears in your toolbar. The icon shows **🔓 Active**.

> **Note:** Temporary installs are removed when Firefox closes. For a permanent
> install you need a signed `.xpi` — ask a sysadmin.

### Permanent install (signed .xpi)

1. Obtain `fosscell-wiki-access.xpi` from your sysadmin (must be Mozilla-signed or
   installed via `about:config` — see note below).
2. Open Firefox → **☰ menu → Add-ons and themes** → gear icon → **Install Add-on From File…**
3. Select the `.xpi` file and click **Add**.

> **Unsigned .xpi on standard Firefox:** Firefox blocks unsigned extensions by default.
> Options:
> - Use **Firefox Developer Edition** or **Firefox Nightly** (they allow unsigned extensions via `about:config` → `xpinstall.signatures.required = false`).
> - Or ask the sysadmin to submit the extension to [addons.mozilla.org](https://addons.mozilla.org) for self-hosted signing.

---

## Firefox (Android)

Firefox Android supports extensions from Firefox 120+.

1. In Firefox Android, open **Settings → Extensions → Install add-on from file**.
   *(If this option is missing, enable it in Settings → About Firefox → tap the logo
   5 times to unlock developer options.)*
2. Transfer the `.xpi` to your phone (USB, cloud storage, or email yourself the file).
3. Open the file manager, tap the `.xpi` — Firefox should prompt you to install it.

---

## Chrome (Desktop)

Chrome uses the same WebExtensions Manifest V3 format.

1. Download and extract `fosscell-wiki-access.zip` to a local folder.
2. Open Chrome → address bar → `chrome://extensions`
3. Enable **Developer mode** (toggle, top-right).
4. Click **Load unpacked** → select the extracted folder.
5. The extension appears in your extensions list. Pin it to the toolbar via the puzzle-piece icon.

> **Note:** Chrome displays "This extension is not from the Chrome Web Store" banners
> in some versions. This is expected for unpacked extensions. It does not affect
> functionality.

---

## Microsoft Edge (Desktop)

Edge supports the same Chromium extension format as Chrome.

1. Extract `fosscell-wiki-access.zip` to a local folder.
2. Open Edge → `edge://extensions`
3. Enable **Developer mode** (toggle, left sidebar).
4. Click **Load unpacked** → select the extracted folder.
5. Pin the extension via the puzzle-piece icon in the toolbar.

---

## Brave (Desktop)

Brave is Chromium-based and installs the same way as Chrome.

1. Extract `fosscell-wiki-access.zip`.
2. Open Brave → `brave://extensions`
3. Enable **Developer mode** (top-right).
4. Click **Load unpacked** → select the extracted folder.

---

## Opera (Desktop)

1. Install the **Install Chrome Extensions** Opera add-on if prompted, or:
2. Go to `opera://extensions` → enable **Developer mode**.
3. Drag-and-drop the `fosscell-wiki-access.zip` (or use **Load unpacked** after
   extracting it).

---

## Safari (macOS)

Safari extensions require a native macOS app wrapper built in Xcode — the `.zip`
extension file cannot be loaded directly. Until a native Safari build is published,
use the **manual User-Agent override** method:

### Safari manual UA override

1. Enable the Develop menu: **Safari → Settings → Advanced** → tick
   **Show features for web developers**.
2. Open **Develop → User Agent → Other…**
3. Copy your current Safari UA from the same menu (e.g.
   `Mozilla/5.0 (Macintosh; Intel Mac OS X ...) AppleWebKit/... Safari/...`)
4. Paste it into the field and **append**:
   ```
    FOSSCellWiki/token=af8675e4daaaf432b2735927e7c4e0dcbd3ac020c1687863
   ```
   (note the leading space)
5. Click **OK**.

> This applies the custom UA to **all sites** in Safari, not just the wiki.
> Reset it afterwards via **Develop → User Agent → Default** if that's a concern.

---

## Mobile Browsers (iOS / Android Chrome)

iOS and Android Chrome/Edge/Brave do not support extensions. Options:

| Option | Effort | Notes |
|---|---|---|
| **Firefox Android** | Low | Supports extensions natively — see Firefox Android section above |
| **Kiwi Browser (Android)** | Low | Chromium-based, supports Chrome extensions. Load via `kiwi://extensions` → **Load unpacked** after extracting the zip |
| **Orion (iOS, macOS)** | Low | Supports both Chrome and Firefox extensions. Load via Settings → Extensions |
| **Manual UA in Chrome Android** | Medium | Requires enabling chrome flags; fiddly |
| **Just use the PoW** | Zero | The challenge takes 1–3 s once, then the cookie is cached for 7 days |

---

## Verifying it works

After installing, open the extension popup from your toolbar. You should see:

```
🔓 Active — token injected
   Anubis challenge bypassed for this browser
```

You can also verify by visiting `wiki.fosscell.org` — you should land directly on
the wiki without any challenge page.

---

## Troubleshooting

**Popup shows "Inactive — Rule not found"**
→ Try disabling and re-enabling the extension in your browser's extensions page,
  or remove and re-install it.

**Still seeing the Anubis challenge after installing**
→ Clear your browser cache and cookies for `wiki.fosscell.org`, then reload.
  The old Anubis challenge cookie may be interfering.

**Extension installs but the wiki still blocks me on Special: pages**
→ The token bypasses the bot challenge (Anubis), but some Special: pages also
  require a **MediaWiki account**. Log in to your wiki account to access those pages.

**Chrome says "This extension is not from the Chrome Web Store"**
→ This is expected for sideloaded extensions. Click **Keep** if prompted during
  install. It does not affect functionality.

---

## For sysadmins — token rotation

If the token is ever leaked or needs refreshing:

```sh
# 1. Generate new token
openssl rand -hex 24

# 2. Update in extension source
#    k8s/apps/wiki-access-extension/background.js  — TOKEN constant
#    k8s/apps/wiki-access-extension/popup.js       — TOKEN constant

# 3. Update in infra configs
#    k8s/clusters/glug-infra/mediawiki/ingress-traefik.yaml  — HeaderRegexp value
#    k8s/clusters/glug-infra/traefik/anubis.yaml             — fosscell-member user_agent_regex

# 4. Apply changes
kubectl apply -f k8s/clusters/glug-infra/mediawiki/ingress-traefik.yaml
kubectl apply -f k8s/clusters/glug-infra/traefik/anubis.yaml
kubectl rollout restart deployment/anubis -n traefik-system

# 5. Rebuild and redistribute the extension zip/xpi to members
cd k8s/apps/wiki-access-extension
zip -r fosscell-wiki-access.zip manifest.json background.js popup.html popup.js
```

The old token stops working as soon as the Traefik IngressRoute update is applied.
