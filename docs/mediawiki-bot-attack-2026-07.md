# MediaWiki Bot Attack — Incident Report & Mitigation
**Date:** 2026-07-01 → 2026-07-05
**Duration:** ~33 hours of active crash-looping before mitigation (first wave);
  second wave (2026-07-05) closed with Anubis CEL rules + CrowdSec firewall bans
**Site:** wiki.fosscell.org
**Status:** ✅ Resolved (CrowdSec CAPI + behavioral bans active)

---

## 1. The Numbers at a Glance

| Metric | During Attack | After Fix | Change |
|---|---|---|---|
| MediaWiki pod restarts | **33 in 33 h** (CrashLoopBackOff) | **0** | −100% |
| Kenobi CPU | **2000 m (100%)** | **700 m (35%)** | −65% |
| Traefik CPU | **800 m** | **215 m** | −73% |
| Anubis CPU | ~17 m | 5 m | −71% |
| Requests/min reaching MediaWiki | **~199 req/min** | ~28 req/min | −86% |
| Special: requests/min reaching PHP | **200+ req/min** | **0 req/min** | **−100%** |
| Bot requests blocked per min (Anubis DENY) | 0 | **16 denies/min** | — |
| Firewall-banned IPs (CrowdSec CAPI) | 0 | **15,000 active bans** | — |
| Unique attacker IPs (10-min window) | unknown | **282 distinct IPs** | — |
| PHP-FPM max workers | 20 | 40 | +100% |
| PHP-FPM worker terminate timeout | 300 s | 90 s | −70% |

---

## 2. The Attacks — Two Separate Incidents

### Attack 1 — `meta-webindexer` on `Special:RecentChangesLinked`

| Field | Value |
|---|---|
| **Bot** | `meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)` |
| **Source** | `57.141.0.0/24` (Meta/Facebook ASN) |
| **Target** | `Special:RecentChangesLinked` |
| **First seen** | 2026-07-01 ~23:43 UTC |

`meta-webindexer` is Meta's aggressive general-purpose web indexer — distinct from
`facebookexternalhit` (the legitimate link-preview bot). It runs **headless Chrome**, so
it solved Anubis's difficulty-4 proof-of-work challenge, obtained a session cookie, then
fired parallel requests across hundreds of parameter permutations:

```
GET /index.php?title=Special:RecentChangesLinked&limit=500&days=30&target=2026:FOSSMeet/Coverage
GET /index.php?title=Special:RecentChangesLinked&limit=250&hidebots=0&days=14&...
GET /index.php?title=Special:RecentChangesLinked&limit=100&hidemyself=1&hideminor=1&...
```

`Special:RecentChangesLinked` runs a full table scan on the `recentchanges` MySQL table.
Each query took 5–15 seconds. The bot had no existing Anubis DENY rule because it didn't
match the `facebookexternalhit|facebookcatalog|Facebot` pattern already in the policy.

---

### Attack 2 — Distributed Drilldown Scraper on `Special:Drilldown`

| Field | Value |
|---|---|
| **Bot** | UA-rotating headless scraper (8 distinct Chrome/Edge strings) |
| **Source** | **282 unique IPs** in a single 10-minute window — a botnet |
| **Target** | `Special:Drilldown/CurriculumCourses` (285 hits/10 min), `Centres`, `CampusLocations` |
| **First seen** | 2026-07-02 ~05:15 UTC |

The bot rotated through 8 realistic Chrome/Edge user-agent strings, distributing load
across a large pool of source IPs to stay under per-IP rate limits:

```
Chrome/145 Edge/145  (Windows)  — 46 hits/10 min
Chrome/145           (Windows)  — 41 hits/10 min
Chrome/144 Edge/144  (Windows)  — 40 hits/10 min
Chrome/143           (Windows)  — 37 hits/10 min
Chrome/142           (Windows)  — 36 hits/10 min
Chrome/144           (Windows)  — 34 hits/10 min
Chrome/145           (macOS)    — 31 hits/10 min
Chrome/144           (macOS)    — 28 hits/10 min
```

Every request also carried `Referer: https://wiki.fosscell.org`, mimicking organic
navigation. This is why Anubis's PoW alone was insufficient — these bots ran real JS
engines capable of solving any challenge given enough time.

`Special:Drilldown` (PageForms/Cargo extension) runs multi-table JOINs with arbitrary
filter combinations, each taking **5–10 seconds** of DB time. With 20 PHP-FPM workers
and requests arriving faster than workers could finish, the pool saturated completely.

---

## 3. The Crash Mechanism

PHP-FPM used a fixed pool of 20 workers. Each Cargo/recentchanges query held a worker
for ~8 seconds. At sustained concurrency the math was inescapable:

```
20 workers × 8 s/query = pool fully saturated at just 2.5 req/s

Crash timeline (repeating every ~3–4 hours):
  T+0 s    Bot fires 20+ concurrent Special: requests
  T+30 s   PHP-FPM logs: WARNING: [pool www] server reached pm.max_children (20)
  T+60 s   Queue fills; PHP workers OOM/crash
           nginx logs: recv() failed (104: Connection reset by peer) × dozens
  T+120 s  healthcheck.php cannot get a free worker → nginx 504
  T+180 s  Liveness probe: 3 consecutive failures × 30 s → kubelet kills container
  T+181 s  Pod restarts. Bot resumes within seconds. Loop repeats.
```

**33 restarts over 33 hours.** The exit code was always `0` (supervisord handled SIGTERM
cleanly), making the crash look like a graceful restart in `kubectl get pods` — masking
the real cause.

---

## 4. Why the Existing Defences Failed

| Defence | Configuration | Why It Failed |
|---|---|---|
| Anubis PoW | Difficulty 4 (~16 hashes) | Both bots run headless Chrome → solved instantly, cookie cached |
| Global rate limit | 30 req/s avg, 60 burst per IP | 282 unique IPs × 30 = 8,460 req/s theoretical budget |
| No `InFlightReq` | Not configured | Nothing capped concurrent connections; 20 slow requests = instant saturation |
| `pm.max_children` | 20 workers | Too few; healthcheck starved when pool was full |
| `request_terminate_timeout` | 300 s | A stuck worker held its slot for 5 minutes before recycling |
| `facebookexternalhit` ALLOW rule | Covered preview bot only | `meta-webindexer` didn't match → fell through to CHALLENGE, solved it |

---

## 5. The Fix — Three-Layer Lockdown

### Layer 1: Anubis — Stop bots before PHP-FPM sees the request

| Change | Before | After |
|---|---|---|
| Global PoW difficulty | 4 (default) | **5** (~1M hashes) — temporarily **10** (~1.1T hashes) during second wave |
| `meta-webindexer` | fell through to CHALLENGE | **DENY** (explicit rule) |
| 20+ expensive Special: pages | passed through to PHP | **DENY outright** (path_regex) |
| Query-string bypass (`/index.php?title=Special:...`) | not covered | **DENY via CEL expression** on decoded `title` parameter |
| `Browse` (SMW) | not covered | added to deny list |
| All remaining `/Special:` paths | passed through | **CHALLENGE difficulty 5** (~1M hashes, ~1 s) |

> **Anubis difficulty is leading zero HEX NIBBLES, so expected work is 16^difficulty,
> NOT 2^difficulty.** An earlier revision of this doc claimed "difficulty 8 ≈ 256
> hashes" and "difficulty 10 ≈ 1024 hashes" — wrong by many orders of magnitude.
> The reality: 16^5 ≈ 1M (~1 s), 16^8 ≈ 4.3 **billion** (minutes-to-hours), 16^10 ≈
> 1.1 **trillion** (hours — unsolvable in a phone browser). The global/Special:
> difficulties were briefly set to 8/10, which locked legitimate users out of even
> the login and account-creation pages. Cranking PoW does NOT stop a resourced
> scraper (it caches the 7-day cookie or swaps in a native/GPU solver) — it only
> maims real users on weak devices. Keep difficulty at **4–5**; the real defense is
> the DENY list + Traefik InFlightReq/rate limits + the PHP anon-block.

Denied pages list: `Drilldown`, `Browse`, `RecentChangesLinked`, `Search`, `Export`, `AllPages`,
`AllFiles`, `Statistics`, `Recentchanges`, `WhatLinksHere`, `LinkedPages`,
`Deadendpages`, `Wantedpages`, `LongPages`, `ShortPages`, `Ancientpages`, `NewFiles`,
`NewPages`, `Protectedpages`, `Listfiles`, `Unusedfiles`, `Unusedtemplates`,
`Uncategorizedpages`, `Uncategorizedcategories`, `BrokenRedirects`, `DoubleRedirects`.

The difficulty-5 challenge is cached in the user's browser cookie for **7 days** — a
real human solves it once per session (~1 s), then never sees it again on repeat visits.
Headless bots must re-solve on every session and cannot pre-cache at scale (though a
resourced scraper that caches the cookie pays this once and scrapes freely — which is
why the DENY list, not the challenge, guards the expensive endpoints).

**2026-07-05 second-wave discovery:** the path_regex DENY only matches the pretty-URL
form (`/Special:Drilldown/...`). The second wave (Attack 2) bypassed it by encoding the
same target as a query parameter (`/index.php?title=Special%3ADrilldown%2F...`), which
`path_regex` never sees. A new `deny-expensive-special-pages-query-form` rule was added
using Anubis's CEL expression support to inspect the decoded `title` query parameter
against the same deny list (case-insensitive). This closes the bypass permanently.

**Exception — `Special:ConfirmEmail` (ALLOW, added 2026-07-05):** the email-confirmation
link is clicked once from a user's inbox, often in a logged-out browser that has never
solved a PoW challenge. An `allow-confirm-email` rule (`path_regex: ^/Special:ConfirmEmail`)
is placed **before** the deny/challenge Special: rules so the link — including the
tokened `/Special:ConfirmEmail/<token>` form — passes straight through. It takes a token,
runs no expensive query, and is not a scraper target. Keep this rule permanently.

Relevant file: `k8s/clusters/glug-infra/traefik/anubis.yaml`

---

### Layer 2: Traefik — Rate and concurrency limits before Anubis

| Middleware | Before | After |
|---|---|---|
| Global rate limit | 30 req/s avg / 60 burst per IP | **8 req/s avg / 15 burst** per real IP |
| Global `InFlightReq` | none | **10 concurrent** per IP |
| Special: rate limit | 3 req/s (3 specific paths only) | **1 req/s / 3 burst** for ALL `/Special:*` |
| Special: `InFlightReq` | none | **3 concurrent** per IP for ALL `/Special:*` |

`InFlightReq` returns **HTTP 503 immediately** when exceeded — no PHP-FPM slot consumed,
no DB query started. A bot firing 20 concurrent Drilldown requests gets 3 queued and 17
instant 503s at the load-balancer layer.

`sourceCriterion: ipStrategy: depth: 1` is used throughout so all limits apply to the
**real client IP** extracted from the first `X-Forwarded-For` header (set by Cloudflare),
not the intermediate Traefik or Anubis pod IP.

Relevant file: `k8s/clusters/glug-infra/mediawiki/ingress-traefik.yaml`

---

### Layer 3: MediaWiki — PHP-level block for anonymous users

Added a `SpecialPageBeforeExecute` hook in `LocalSettings.php` that blocks all Special:
page access for unauthenticated users. Only the login/account-lifecycle pages are
whitelisted:

```php
$loginPages = [
    'UserLogin', 'Userlogin', 'CreateAccount', 'PasswordReset', 'Userlogout',
    'ConfirmEmail', 'Confirmemail', // email confirmation link (added 2026-07-05)
];
```

`ConfirmEmail` is whitelisted because the confirmation link may be clicked from a
logged-out browser; without it, anonymous users hit a 403 before the token is validated.
Keep it whitelisted permanently — it runs no expensive query.

Everything else returns a permissions error **before touching the database**. Even if a
bot somehow bypasses Traefik and Anubis, it receives a 403 from PHP with zero DB
queries executed.

The only Special: requests reaching PHP after the fix are legitimate login, account
creation, and email-confirmation flows — exactly as intended.

Relevant file: `k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml`

---

### Layer 4: PHP-FPM — Make the pod resilient under load

The existing `zz-tuning.conf` in the container image set `pm.max_children = 20` and
`request_terminate_timeout = 300`. A new `zzz-max-children.conf` ConfigMap is mounted
into the container at `/usr/local/etc/php-fpm.d/zzz-max-children.conf`. The `zzz-`
prefix ensures it loads **after** `zz-tuning.conf` (alphabetical order) and wins.

| Setting | Before | After | Why |
|---|---|---|---|
| `pm.max_children` | 20 | **40** | Kenobi has 4 GiB reserved for mediawiki; 40 × ~80 MB = 3.2 GiB — fits safely |
| `request_terminate_timeout` | 300 s | **90 s** | Stuck workers freed in 90 s, not 5 minutes |
| `pm.max_requests` | unlimited | **500** | Workers recycled after 500 requests; prevents PHP memory leaks |

Relevant file: `k8s/clusters/glug-infra/mediawiki/phpfpm-configmap.yaml`

---

### Layer 5: CrowdSec — Host-level firewall bouncer (added 2026-07-05)

After the second wave bypassed the Anubis path_regex, CrowdSec was deployed on kenobi
as a NixOS service (`hosts/kenobi/parts/crowdsec.nix`). It runs outside Kubernetes
and enforces bans at the iptables/ipset level before traffic reaches Traefik.

| Component | Detail |
|---|---|
| **Log source** | Traefik JSON access logs written to `/var/log/traefik/access.log` via hostPath |
| **Acquisition** | CrowdSec filesource tails the log file; s00-raw parser tags `program=traefik` |
| **Parser** | `crowdsecurity/traefik-logs` — Traefik JSON log parser |
| **Scenarios** | `crowdsecurity/http-crawl`, `crowdsecurity/http-probing`, `crowdsecurity/http-cve`,
  `crowdsecurity/http-sensitive-files`, plus custom `glug/http-deny-flood` (IPs with 10+ 403/429) |
| **Community blocklist** | CAPI enrolled — ~15,000 active bans from the global CrowdSec network |
| **Enforcement** | `crowdsec-firewall-bouncer` — iptables/ipset on kenobi's INPUT chain, drops before Traefik |
| **Internal whitelist** | Tailscale (`100.64.0.0/10`), pod CIDR (`10.42.0.0/16`), service CIDR (`10.43.0.0/16`) excluded |
| **Metrics** | Prometheus endpoint on `kenobi:6060`, scraped by VMAgent via `VMStaticScrape` |
| **Dashboard** | `CrowdSec — CAPI & Engine` in Grafana (Security folder) — CAPI bans, acquisition, scenarios |

Key architecture decisions:
- CrowdSec runs on the **host** (NixOS), not in a pod — bans take effect at the kernel
  before Traefik or PHP-FPM spends any CPU.
- The firewall bouncer uses iptables mode (not nftables) to match kenobi's existing
  `networking.firewall` setup. It is `partOf` the firewall service so bans survive reloads.
- No sops secrets needed: LAPI machine registration is automatic (`cscli machine add --auto`),
  CAPI enrollment is automatic (`cscli capi register`), and the firewall bouncer
  self-registers via `cscli bouncers add`.

Upstream module bugs worked around in `hosts/kenobi/parts/crowdsec.nix`:
1. CAPI credentials file must pre-exist (tmpfiles creates it empty; capi register fills it)
2. Firewall bouncer register script uses raw `cscli` — overridden to pass `-c` with the
   Nix store config path
3. Register unit had no `after` ordering on the bouncer — added explicit ordering
4. Register unit's `DynamicUser=true` with `StateDirectory=crowdsec` corrupted the
   agent's shared state directory — disabled DynamicUser for the register unit

---

## 6. Resource Relief Taken During Incident

To recover headroom on the single-node kenobi while the fix was being deployed, the
following were scaled to zero (not related to the wiki):

| Namespace | What | How to restore |
|---|---|---|
| `cnpg-system` | CloudNativePG operator | `kubectl scale deploy -n cnpg-system --all --replicas=1` |
| `cnpg-clusters` | postgres-cluster (hibernated) | Remove `cnpg.io/hibernation=on` annotation; scale pooler back to 3 |
| `monitoring` | Victoria Metrics stack, Grafana, VictoriaLogs, vmagent, vmalert | `kubectl scale deploy,sts -n monitoring --all --replicas=1` |
| `ghost` | Ghost CMS, ActivityPub, pubsub | `kubectl scale deploy -n ghost --all --replicas=1` |
| `mysql-ghost` | ProxySQL + 3-node MGR | `kubectl scale sts -n mysql-ghost --all --replicas=1 && kubectl scale deploy/proxysql-ghost -n mysql-ghost --replicas=1` |
| `penpot` | Penpot + Valkey | `kubectl scale deploy -n penpot --all --replicas=1` |
| `memos`, `answer`, `conduit`, `wikifeeds` | Various apps | `kubectl scale deploy,sts -n <ns> --all --replicas=1` |
| `rustfs-clusters` | RustFS + nginx proxy + mc-mirror | `kubectl scale deploy,sts -n rustfs-clusters --all --replicas=1` |

Restore in order: mysql-ghost → ghost → cnpg → monitoring → rest.
Wait for kenobi CPU to settle below 70% between each group.

---

## 7. Current State (post-fix)

```
Pods:
  mediawiki-7598fdd458-7cpkx   2/2 Running   0 restarts ✅
  mediawiki-7598fdd458-dnlkh   2/2 Running   0 restarts ✅
  anubis-b88d7b4b8-xxxxx      1/1 Running   0 restarts ✅ (CEL deny rules active)

Kenobi:
  CPU:    700 m / 2000 m  (35%)    was 2000 m (100%)
  Memory: 9.3 Gi / 12 Gi  (78%)   — includes CrowdSec + monitoring

CrowdSec:
  Lines parsed/s:          ~734 / 30s
  Active CAPI bans:         14,980  (http:scan 14,429, http:exploit 320,
                                       http:bruteforce 221, http:crawl 30)
  Custom scenario pours:    6,204  (glug/http-deny-flood — 403/429 recidivists)
  Bouncer:                  active, iptables/ipset, 362 MB processed

Traefik:   215 m    was 800 m  (−73%)
Anubis:      5 m    was  17 m  (−71%)

Live traffic (at time of writing):
  Bot denies/min (Anubis):           16  (hitting path_regex + CEL query-form rules)
  CAPI firewall drops (kernel):      ~continuous  (15K banned IPs dropped before Traefik)
  Special: requests reaching PHP:    0    (denied at Anubis or blocked by firewall)
  Total requests reaching MediaWiki: ~28 req/min
  Unique attacker IPs still active:  282+ (still incoming, all denied at multiple layers)
```

The scraper is still firing, but every request is stopped at one of three layers:
1. **iptables/ipset (CrowdSec)** — 15K known-bad IPs dropped at the kernel
2. **Anubis DENY** — expensive Special: pages blocked on both path and query forms
3. **Traefik rate limits** — residual cheap-page requests kept under 1 req/s per IP

No PHP-FPM worker has been consumed by a bot request since the CrowdSec deployment.

---

## 8. Lifting the Lockdown

When bot traffic subsides and services are restored, loosen the restrictions in this
order:

**Step 1 — Reset Anubis PoW difficulty from 10 back to 5**

The global and Special: challenge difficulties were raised to 10 (~1.1T hashes) during
the second wave. 16^10 is solvable in ~2 minutes on a GPU but locks out real users on
phones for hours. The CEL query-form DENY + CrowdSec firewall are now the primary
defences; cranking difficulty only hurts legitimate users.

In `k8s/clusters/glug-infra/traefik/anubis.yaml`, revert both the `DIFFICULTY` env var
(line 49) and the `challenge-all-special-pages` rule's difficulty (line 179) back to `5`.
Then: `kubectl apply -f k8s/clusters/glug-infra/traefik/anubis.yaml && kubectl rollout
restart deployment/anubis -n traefik-system`.

**Step 2 — Re-open Special: pages to anonymous users** (when attack stops)

Edit `k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml`. Expand the
`$loginPages` whitelist to restore public access to specific pages:

```php
// Add back as traffic permits:
'Special:Search',          // public search (CirrusSearch/OpenSearch load)
'Special:RecentChanges',   // read-only, low cost
'Special:Random',          // single random redirect, negligible
```

Roll mediawiki: `kubectl rollout restart deployment/mediawiki -n mediawiki`

**Step 3 — Restore Anubis DENY list to less aggressive** (after a few quiet days)

In `k8s/clusters/glug-infra/traefik/anubis.yaml`, remove `Search` and `Recentchanges`
from the `deny-expensive-special-pages` path_regex once they're back in the MW whitelist.
Keep `Drilldown`, `Browse`, and `RecentChangesLinked` denied permanently — they have no
legitimate anonymous use case and are magnets for scrapers.

**Step 4 — Restore scaled-down services**

```sh
# Restore in priority order, check CPU between each:
kubectl scale deploy,sts -n mysql-ghost --all --replicas=1
kubectl scale deploy -n ghost --all --replicas=1
kubectl scale deploy -n cnpg-system --all --replicas=1
kubectl annotate cluster postgres-cluster -n cnpg-clusters cnpg.io/hibernation- --overwrite
kubectl scale deploy -n cnpg-clusters --all --replicas=3
kubectl scale deploy,sts -n monitoring --all --replicas=1
# then memos, penpot, answer, conduit, wikifeeds, rustfs as CPU allows
```

---

## 9. Permanent Recommendations

1. **Keep `Special:Drilldown` and `Special:RecentChangesLinked` login-gated permanently.**
   They run unbounded SQL and are crawled aggressively. There is no legitimate SEO or
   anonymous-access reason to expose them publicly.

2. **Add a robots.txt `Disallow` for `/Special:` paths.** Anubis serves `robots.txt`
   (`SERVE_ROBOTS_TXT=true`). Well-behaved crawlers (Googlebot) will honour it and stop
   generating noise that exercises the rate-limit state machine in Traefik.

3. **CrowdSec is now deployed and active.** The firewall bouncer on kenobi enforces
   ~15,000 community blocklist bans at the kernel level. This is the primary defence
   against known-bad IPs and should be maintained. Monitor CAPI ban counts and scenario
   overflows via the Grafana dashboard (Security folder — `CrowdSec — CAPI & Engine`).

4. **The `deny-expensive-special-pages-query-form` CEL rule is permanent.** The
   query-string bypass was the critical gap. Anubis's `path_regex` cannot inspect query
   parameters; the CEL expression on the decoded `title` parameter is the correct fix
   and should stay even if the Anubis difficulty is lowered.

5. **Keep `Special:Drilldown`, `Special:Browse`, and `Special:RecentChangesLinked`
   login-gated permanently.** They run unbounded SQL and are crawled aggressively. There
   is no legitimate SEO or anonymous-access reason to expose them publicly.
