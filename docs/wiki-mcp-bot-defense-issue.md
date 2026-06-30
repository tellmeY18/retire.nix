# Draft issue for Wiki-NITC/wiki-mcp

> Could not be filed automatically — the GitHub token lacks `Issues: write` on the
> `Wiki-NITC` org. Either widen the PAT (add `Wiki-NITC/wiki-mcp`, Issues: Read/write)
> and re-run, or paste the body below into a new issue manually.

**Title:** Bot defense: allowlist NITC agent traffic via a rotating custom User-Agent at the edge

---

## Background — why we need this

`wiki.fosscell.org` has been hit by a sustained distributed AI-scraper flood. The
access logs show hundreds of unique IPs hammering the **most expensive** MediaWiki
endpoints (`Special:Drilldown/CurriculumCourses`, `Special:RecentChangesLinked`,
`Special:UserLogin`/`CreateAccount` login traps, `Special:Contributions`,
`?action=edit/history`, `?diff=`/`?oldid=` …), mostly with an **empty `User-Agent`**
(`"-"`).

That load saturated the single MediaWiki node and knocked over the public ingress
(Traefik was being liveness-killed in a restart loop). Root cause at the edge:
**Anubis was running its built-in default policy, which is allow-by-default** and
only challenges User-Agents containing `Mozilla`. Empty-UA requests matched no rule →
passed straight through to MediaWiki.

## Infra-side lockdown (being deployed in the cluster repo)

A custom Anubis bot policy now (first-match-wins, top→bottom):

- `ALLOW` Anubis' own assets, `/.well-known`, `robots.txt`, `favicon`
- `ALLOW` verified search engines (Googlebot/Bingbot/…)
- `DENY` known AI scraper UAs (GPTBot, ClaudeBot, CCBot, Bytespider, Amazonbot, …)
- **`CHALLENGE` empty/missing `User-Agent`** (the current flood) — bots without
  JS fail the PoW, acting as a per-IP rate limiter
- `CHALLENGE` expensive `Special:` pages + any browser-like (`Mozilla`) UA
- extreme lockdown default so unknown automation can't free-ride

This shrinks bots to bare-minimum activity and gives the MediaWiki pod room to
breathe. **But it also means our own agents must be explicitly recognised at the
edge** — proof-of-work is a JS challenge a headless MCP client cannot solve.

## Proposal — a custom, rotating agent User-Agent that the edge allowlists

Give every NITC agent invocation a distinctive `User-Agent` carrying a shared token.
The edge (Anubis) gets a top-priority `ALLOW` rule matching it, so agent traffic
bypasses the challenge and the throttles entirely:

```
NITCWikiAgent/1.0 (+https://github.com/Wiki-NITC/wiki-mcp; token=<SECRET>)
```

- `<SECRET>` is a low-sensitivity shared token. It can be semi-public and is
  **rotated occasionally**. It is *not* a real authN boundary (a UA is trivially
  spoofable) — it's a coarse "this is one of ours, don't challenge it" signal. Real
  write-protection still comes from the bot-password/login identity MediaWiki already
  enforces.
- Rotating it lets us cut off a leaked token by flipping one regex on the edge.

### Important constraint found in the upstream server

`wiki-mcp` wraps `@professional-wiki/mediawiki-mcp-server@0.10.0`, which **hardcodes**
the User-Agent:

```ts
// src/runtime/constants.ts
export const USER_AGENT = `${SERVER_NAME}/${serverInfo.version}`;  // "mediawiki-mcp-server/0.10.0"
```

Used in `src/wikis/mwnProvider.ts` (mwn/edit path) and `src/transport/httpFetch.ts`
(raw fetch). It is **not** configurable via env/config in 0.10.0. So we have three
paths:

1. **Interim (zero code):** allowlist the deterministic upstream UA
   `mediawiki-mcp-server/<version>` at the edge. Works today, but anyone can spoof
   that exact string (no secret).
2. **Robust (preferred):** get a configurable UA upstream — file a feature request on
   ProfessionalWiki/MediaWiki-MCP-Server for a `USER_AGENT` / `MEDIAWIKI_MCP_USER_AGENT`
   env override — then set our secret UA via `.env` (our `scripts/start-mcp.sh`
   already sources `.env`).
3. **Stopgap:** carry a tiny patch/wrapper in `wiki-mcp` that sets the UA until
   upstream lands (1).

## Tasks

**`wiki-mcp` (this repo)**
- [ ] Decide the UA format + token scheme above; store the current token where testers
      can fetch it (and document rotation).
- [ ] Wire a `WIKI_MCP_USER_AGENT` (or token) value through `.env` → the server.
      Pursue upstream env support (path 2); add interim allowlist (path 1) meanwhile.
- [ ] Add a `rules/` doc (e.g. `rules/edge-access.md`) describing the UA contract:
      *every agent invocation must send the NITC agent User-Agent*; explain why (edge
      bot lockdown) and how to rotate.
- [ ] Reflect it in `.agents/skills/nitc-wiki-editing/SKILL.md` and `Agents.md`
      (under "what's actually enforced").
- [ ] README note for beta testers (no extra setup if baked into `start-mcp.sh`).

**Cluster/infra repo (tracked separately, linked here)**
- [x] Top-priority Anubis `ALLOW` rule matching the agent UA regex (rotating token).
- [x] Keep the lockdown rules (deny empty-UA + known scrapers, challenge expensive
      `Special:` + browsers).
- [x] Document token rotation = update one regex + redeploy.

> Infra side implemented in this cluster repo:
> `k8s/clusters/glug-infra/traefik/anubis-policy.yaml` (a top-priority
> `nitc-agent` ALLOW rule matching the rotating token) and
> `docs/wiki-edge-bot-defense.md` (rotation procedure). Deployed + verified on
> the glug-infra cluster 2026-07-01: valid-token UA passes the edge; known AI
> scrapers (GPTBot, …) are denied by Anubis' bundled import lists. NOTE: the
> live policy is currently allow-by-default (it denies curated bad bots but does
> NOT yet block empty-UA or challenge plain browsers) — tightening that default
> is a separate, higher-risk change. Current token lives in the `nitc-agent`
> rule's `token=...` literal; rotate by updating it there and in `wiki-mcp`,
> then `kubectl apply` + `kubectl rollout restart deploy/anubis`.

## Security notes
- A `User-Agent` is spoofable; this is intentionally a **soft allowlist** to stop
  indiscriminate scrapers, not an auth gate. Rotation + low value makes it an
  acceptable trade-off.
- Write operations remain protected by the existing bot-password/login flow — the UA
  only governs edge rate-limit/challenge exemption.
- For a hard boundary later, we can move agents to MediaWiki OAuth2 and validate at
  the edge; out of scope here.
