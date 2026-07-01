# MediaWiki Bot Attack — Incident Report & Mitigation
**Date:** 2026-07-01 → 2026-07-02
**Duration:** ~33 hours of active crash-looping before mitigation
**Site:** wiki.fosscell.org
**Status:** ✅ Resolved

---

## 1. The Numbers at a Glance

| Metric | During Attack | After Fix | Change |
|---|---|---|---|
| MediaWiki pod restarts | **33 in 33 h** (CrashLoopBackOff) | **0** | −100% |
| Kenobi CPU | **2000 m (100%)** | **969 m (48%)** | −51% |
| Traefik CPU | **800 m** | **215 m** | −73% |
| Anubis CPU | ~17 m | 5 m | −71% |
| Requests/min reaching MediaWiki | **~199 req/min** | ~75 req/min | −62% |
| Special: requests/min reaching PHP | **200+ req/min** | **0.4 req/min** | **−99.8%** |
| Bot requests blocked per min (live) | 0 | **55 denies/min** | — |
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
| Global PoW difficulty | 4 (~16 hashes, instant) | **8** (~256 hashes, ~0.5 s on phone) |
| `meta-webindexer` | fell through to CHALLENGE | **DENY** (explicit rule) |
| 20+ expensive Special: pages | passed through to PHP | **DENY outright** |
| All remaining `/Special:` paths | passed through | **CHALLENGE difficulty 10** (~1024 hashes, 1–3 s) |

Denied pages list: `Drilldown`, `RecentChangesLinked`, `Search`, `Export`, `AllPages`,
`AllFiles`, `Statistics`, `Recentchanges`, `WhatLinksHere`, `LinkedPages`,
`Deadendpages`, `Wantedpages`, `LongPages`, `ShortPages`, `Ancientpages`, `NewFiles`,
`NewPages`, `Protectedpages`, `Listfiles`, `Unusedfiles`, `Unusedtemplates`,
`Uncategorizedpages`, `Uncategorizedcategories`, `BrokenRedirects`, `DoubleRedirects`.

The difficulty-10 challenge is cached in the user's browser cookie for **7 days** — a
real human solves it once per session (1–3 s), then never sees it again on repeat visits.
Headless bots must re-solve on every session and cannot pre-cache at scale.

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
page access for unauthenticated users. Only four pages are whitelisted:

```php
$loginPages = [ 'UserLogin', 'Userlogin', 'CreateAccount', 'PasswordReset', 'Userlogout' ];
```

Everything else returns a permissions error **before touching the database**. Even if a
bot somehow bypasses Traefik and Anubis, it receives a 403 from PHP with zero DB
queries executed.

The only Special: requests reaching PHP after the fix are legitimate login and account
creation flows — exactly as intended.

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
  mediawiki-74744fc55d-4pkjp   2/2 Running   0 restarts ✅
  mediawiki-74744fc55d-jfwwr   2/2 Running   0 restarts ✅

Kenobi:
  CPU:    969 m / 2000 m  (48%)    was 2000 m (100%)
  Memory: 4383 Mi / 12 GiB (36%)

Traefik:   215 m    was 800 m  (−73%)
Anubis:      5 m    was  17 m  (−71%)

Live traffic (at time of writing):
  Bot denies/min:                   55  (all hitting Anubis DENY wall)
  Special: requests reaching PHP:    0.4 req/min  (UserLogin/CreateAccount only)
  Total requests reaching MediaWiki: 75 req/min
  Unique attacker IPs still active:  282+ (still incoming, all denied)
```

The scraper **is still running**. It is firing ~55 requests/minute from 282+ unique IPs.
Every single one now hits the `deny-expensive-special-pages` rule in Anubis and is
rejected before consuming any PHP-FPM worker capacity.

---

## 8. Lifting the Lockdown

When bot traffic subsides and services are restored, loosen the restrictions in this
order:

**Step 1 — Re-open Special: pages to anonymous users** (when attack stops)

Edit `k8s/clusters/glug-infra/mediawiki/localsettings-configmap.yaml`. Expand the
`$loginPages` whitelist to restore public access to specific pages:

```php
// Add back as traffic permits:
'Special:Search',          // public search (CirrusSearch/OpenSearch load)
'Special:RecentChanges',   // read-only, low cost
'Special:Random',          // single random redirect, negligible
```

Roll mediawiki: `kubectl rollout restart deployment/mediawiki -n mediawiki`

**Step 2 — Restore Anubis DENY list to less aggressive** (after a few quiet days)

In `k8s/clusters/glug-infra/traefik/anubis.yaml`, remove `Search` and `Recentchanges`
from the `deny-expensive-special-pages` path_regex once they're back in the MW whitelist.
Keep `Drilldown` and `RecentChangesLinked` denied permanently — they have no legitimate
anonymous use case and are magnets for scrapers.

**Step 3 — Restore scaled-down services**

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

3. **Consider CrowdSec bouncer for Traefik.** The `crowdsec-bouncer-traefik-plugin` is
   the only first-class Traefik plugin for IP reputation blocking. It would have blocked
   the 282-IP botnet at the network layer before TLS termination, eliminating the
   Traefik CPU cost entirely. Evaluate for the next incident.

4. **Add a Prometheus alert for `pm.max_children reached`.** The PHP-FPM warning
   `server reached pm.max_children setting` appeared in logs 6 minutes before the first
   crash. A VictoriaMetrics alert on `phpfpm_max_children_reached_total > 0` would have
   paged before the liveness probe failed.

5. **The `healthcheck.php` liveness probe is a weak signal.** It passes through nginx →
   PHP-FPM → Redis/DB. Under worker exhaustion it's the *first* thing to fail, which is
   the right behaviour — but `failureThreshold: 3` with `periodSeconds: 30` means 90 s
   of downtime per crash before kubelet acts. Consider lowering to `periodSeconds: 10,
   failureThreshold: 3` (30 s detection window) once the pod is stable.
