# wiki.fosscell.org — Progress Log

Track of all structural changes made to the wiki. Newest entries first.

---

## 2026-05-17 — FOSSMeet Template System & Namespace Migration

### What was done

**Year-based namespaces (Wikimania-style):**
- Added to `LocalSettings.php`: dynamic namespace loop `1961` → `currentYear + 2`
- Every year gets a content + talk namespace pair (IDs 3000+)
- Subpages enabled, default search included, CirrusSearch indexed
- Academic planning gets 2 years ahead (2028 available today)

**Job runner sidecar:**
- Added `jobrunner` container to MediaWiki deployment
- Continuously drains the job queue (50 jobs/batch, 2s sleep)
- `$wgJobRunRate = 0` — web requests no longer run jobs
- Template edits now auto-purge all using pages within seconds

**Templates created/updated:**

| Template | Purpose | Status |
|---|---|---|
| `Template:Infobox FOSSMeet` | 40+ field infobox, Wikipedia-style (22em, HTML `<tr>`, no section headers) | ✅ Live |
| `Template:FOSSMeet Tabs` | Top portal bar: Main · Schedule · Speakers · Team · Roadmap · Gallery · Coverage | ✅ Live |
| `Template:FOSSMeet Navbox` | Bottom nav linking all editions + meta pages | ✅ Live |

**Pages created in `2026:` namespace:**

| Page | Content |
|---|---|
| `2026:FOSSMeet` | Main page with infobox, highlights, see-also |
| `2026:FOSSMeet/Schedule` | 3-day schedule tables |
| `2026:FOSSMeet/Speakers` | Sortable 18-speaker table |
| `2026:FOSSMeet/Team` | Sub-committees (stub) |
| `2026:FOSSMeet/Roadmap` | 31-milestone planning timeline (completed reference) |
| `2026:FOSSMeet/Gallery` | 5-photo gallery |
| `2026:FOSSMeet/Coverage` | Blog/press stubs |

**Pages created in `2027:` namespace:**

| Page | Content |
|---|---|
| `2027:FOSSMeet` | Placeholder main page for next edition |
| `2027:FOSSMeet/Roadmap` | Active planning tracker — all milestones TBD |

**Redirects set up:**
- `FOSSMeet'26` → `2026:FOSSMeet`

### What's next (FOSSMeet)

- [ ] Purge caches on all old FOSSMeet pages using the template
- [ ] Migrate `FOSSMeet'25` → `2025:FOSSMeet` (rich data available)
- [ ] Migrate `FOSSMeet'24` → `2024:FOSSMeet` (27 speakers, full schedule needed)
- [ ] Migrate `FOSSMeet 2013` → `2013:FOSSMeet` (richest historical data — full multi-track schedule)
- [ ] Migrate `FOSSMeet 2014` → `2014:FOSSMeet` (tribute edition, full schedule)
- [ ] Migrate `FOSSMeet 2007` → `2007:FOSSMeet` (rich blogs, chief guest, community meetups)
- [ ] Backfill stub editions ('05, '06, '08–'12, '16–'19, '23) with basic infobox data
- [ ] Update `FOSSMEET` overview page to link to new namespace URLs
- [ ] Delete/redirect old page names once all content is migrated

### What's next (broader wiki)

- [ ] Phase 1 — Spam cleanup (block 3 sleeper accounts)
- [ ] Phase 2 — Duplicate resolution (wrong redirects, content merges)
- [ ] Phase 3 — Category overhaul (create tree, mass-tag 257 pages)
- [ ] Design event template system for Tathva, Ragam (same YYYY:Event pattern)
- [ ] Design `Template:Infobox Club`, `Template:Infobox Person` etc.
- [ ] Create year-namespace pages for historical campus events

---

## Architecture Decisions

### ADR-1: Year namespaces over flat page names
- **Decision:** Use MediaWiki custom namespaces (`2026:FOSSMeet`) instead of flat titles (`FOSSMeet 2026` or `FOSSMeet'26`)
- **Reason:** Scoped search, `Special:AllPages` filtering, `{{NAMESPACE}}`/`{{PAGENAME}}` magic words, per-namespace protection, shared namespace for all events in a year
- **Trade-off:** Requires `LocalSettings.php` config; old pages need redirect

### ADR-2: HTML `<tr>` over wikitext `|-` in templates
- **Decision:** All infobox templates use raw HTML table rows inside `{{#if:}}` blocks
- **Reason:** Wikitext `|-` inside parser functions is unreliably parsed by MediaWiki (the `|-` appears as literal text). HTML tags are always processed correctly.
- **Trade-off:** Slightly less readable template source, but 100% reliable rendering

### ADR-3: Dedicated job runner sidecar
- **Decision:** Add a `jobrunner` sidecar container instead of relying on `$wgJobRunRate`
- **Reason:** Low-traffic wiki accumulates thousands of queued jobs (1,417 at time of discovery). Template cache purges were never reaching pages.
- **Trade-off:** ~128Mi extra RAM per pod, negligible CPU

### ADR-4: Roadmap as a subpage
- **Decision:** Every event edition gets a `/Roadmap` subpage tracking planning milestones
- **Reason:** FOSSMeet planning knowledge was lost between generations. A structured 31-milestone timeline ensures reproducibility and institutional memory.
- **Source:** Derived from `FOSSMeet CheckList` (operational notes from '24 organisers)
