# Wiki edge bot defense (Anubis) — server-side allowlist

Edge bot protection for `wiki.fosscell.org`. This is the **infra/cluster side**
of the work described in `docs/wiki-mcp-bot-defense-issue.md`. The agent
(client) side — sending the rotating User-Agent — is handled in the
`Wiki-NITC/wiki-mcp` repo.

## Where it lives

| Resource | File |
|---|---|
| Anubis Deployment + Service + ForwardAuth Middleware | `k8s/clusters/glug-infra/traefik/anubis.yaml` |
| Bot policy (the rules) | `k8s/clusters/glug-infra/traefik/anubis-policy.yaml` |
| MediaWiki IngressRoute (routes through Anubis) | `k8s/clusters/glug-infra/mediawiki/ingress-traefik.yaml` |

Request flow:

```
client → Traefik (websecure) → ForwardAuth(Anubis) → MediaWiki
                                     │
                                     ├─ ALLOW    → pass straight through
                                     ├─ DENY     → "Oh noes!" error page (MW untouched)
                                     └─ CHALLENGE→ JS proof-of-work page
```

> NOTE: the running policy uses ConfigMap key `policy.yaml`, mounted at
> `/etc/anubis` (`POLICY_FNAME=/etc/anubis/policy.yaml`). Keep `anubis.yaml`
> and `anubis-policy.yaml` in sync with this — they were reconciled to the
> live cluster state on 2026-07-01. Last updated: empty-UA CHALLENGE added.

## Current policy (first-match-wins, top → bottom)

1. **`ALLOW` NITC agent** — `NITCWikiAgent/<ver> (... token=<SECRET>)` (rotating)
2. `DENY` pathological scrapers (`import (data)/bots/_deny-pathological.yaml`,
   `aggressive-brazilian-scrapers.yaml`)
3. `DENY` AI/LLM bots (`import (data)/meta/ai-block-aggressive.yaml`) — GPTBot,
   ClaudeBot, CCBot, Bytespider, etc.
4. **`CHALLENGE` empty User-Agent** (the current flood vector) — bots without
   JS fail the PoW, so this acts as a per-IP rate limiter
5. `ALLOW` verified search engines (`import (data)/crawlers/_allow-good.yaml`)
6. `ALLOW` social/embed crawlers (Facebook, Twitter, Discord, Slack, …) for OG previews
7. `ALLOW` well-known paths (`import (data)/common/keep-internet-working.yaml`)
8. `ALLOW` the MediaWiki API (`/api.php`, `/rest.php`) — programmatic access
9. `CHALLENGE` Firefox AI previews (`import (data)/clients/x-firefox-ai.yaml`)
10. (default) unmatched requests are **ALLOWED** (Anubis allow-by-default)

## The NITC agent allowlist (rotating token)

Our MCP client cannot solve the JS proof-of-work challenge, so it must be
recognised at the edge. It sends:

```
NITCWikiAgent/1.0 (+https://github.com/Wiki-NITC/wiki-mcp; token=<SECRET>)
```

The `nitc-agent` rule is placed **first** and `ALLOW`s it before any deny or
challenge rule. Two reasons it matters even though the policy is allow-by-default
today:

- It future-proofs the agent: if the default is later tightened to
  deny/challenge, our traffic still passes.
- A single rotating literal gives us a kill-switch for a leaked token.

**This is a soft allowlist, not authentication.** A User-Agent is trivially
spoofable; the token is low-sensitivity and may be semi-public. Real
write-protection still comes from MediaWiki's bot-password/login flow — the
token only governs edge challenge/rate-limit exemption.

## Rotating the token

The token must match **byte-for-byte** on both sides.

1. Generate a new token:
   ```sh
   openssl rand -hex 16
   ```
2. **Infra side (this repo):** update the `token=...` literal in the
   `nitc-agent` rule in `k8s/clusters/glug-infra/traefik/anubis-policy.yaml`,
   then redeploy + reload (Anubis reads the policy at startup):
   ```sh
   export KUBECONFIG=~/.kube/glug-infra.yaml
   kubectl apply -k k8s/clusters/glug-infra/traefik
   kubectl rollout restart deploy/anubis -n traefik-system
   ```
3. **Agent side (`wiki-mcp`):** set the same token in the
   `WIKI_MCP_USER_AGENT` / token value the server sends, and redeploy it.

To **revoke** a leaked token, just rotate — the old literal stops matching the
moment the new policy is applied and Anubis restarts.

## Verifying

```sh
export KUBECONFIG=~/.kube/glug-infra.yaml

# 1. Policy loaded without parse errors:
kubectl logs -n traefik-system deploy/anubis --tail=5 | grep -i policy

# 2. NITC agent (valid token) → real MediaWiki page:
curl -sL -A 'NITCWikiAgent/1.0 (+https://github.com/Wiki-NITC/wiki-mcp; token=<SECRET>)' \
  https://wiki.fosscell.org/wiki/Main_Page | grep -oiE '<title>[^<]*</title>'
#   → <title>... - WIKI FOSSCELL NITC</title>

# 3. A denied AI scraper → Anubis "Oh noes!" page:
curl -sL -A 'Mozilla/5.0 (compatible; GPTBot/1.1; +https://openai.com/gptbot)' \
  https://wiki.fosscell.org/wiki/Main_Page | grep -oiE '<title>[^<]*</title>'
#   → <title>Oh noes!</title>

# 4. Empty User-Agent (flood vector) → Anubis challenge page:
curl -sL -A '' https://wiki.fosscell.org/index.php/Main_Page | head -6
#   → <title>Making sure you're not a bot!</title>
```
