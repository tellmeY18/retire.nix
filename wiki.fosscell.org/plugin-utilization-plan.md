# Plugin Utilization Plan — wiki.fosscell.org

> **Status:** Evaluation + roadmap
> **MediaWiki:** 1.45.3 (image build-53)
> **Generated:** 2026-06-01 from a live audit of installed extensions, Cargo tables, namespaces, and key pages.
> **Companion docs:** `ROADMAP.md` (cleanup), `pageforms-migration.md` (forms), `migration.md` (year namespaces)

---

## 0. Executive Summary

We just installed 17 extensions but most are **loaded but unused**. This plan finds concrete, high-value places to use each one and sequences the work. The wiki already has good bones: Cargo tables, year namespaces (1961–2028), ~22 infobox templates, a custom Main Page, and PageForms forms (Centre, Club, Home Team).

**Biggest wins, ranked:**
1. **Lingo** — auto-glossary for FOSS/NITC jargon across all 290 articles (zero per-page effort)
2. **WikiSEO** — proper search/social metadata (currently only a generic OG hook)
3. **SemanticResultFormats** — turn flat lists into calendars, timelines, charts
4. **Mermaid** — org charts, fest timelines, campus wayfinding diagrams
5. **Maps** — interactive campus map (we have 100+ location pages, zero maps)
6. **ExternalData** — live placement/news data from nitc.ac.in
7. **Widgets** — Instagram/YouTube/Maps embeds done safely
8. **Translate** — Malayalam for key public pages

---

## 1. Current Utilization Audit

| Extension | Loaded | Currently Used? | Gap |
|---|---|---|---|
| PageForms | ✅ | 🟢 Live | 14 forms, all category-linked; Edit-with-form tab verified |
| PageSchemas | ✅ | ❌ No | No schemas defined |
| Lingo | ✅ | ✅ Live | `Terminology` seeded; tooltips rendering in mainspace |
| WikiSEO | ✅ | ✅ Live | `{{#seo:}}` in Centre infobox + `{{SEO}}` helper; custom OG hook retired |
| Widgets | ✅ | ⚠️ Blocked | `Widget:` namespace protected; needs `editwidgets` grant + rollout |
| Maps | ✅ | 🟢 Live | [[NITC Campus Map]] (Leaflet/OSM) + infobox mini-maps; 10 OSM-geocoded locations in Cargo |
| Mermaid | ✅ | 🟢 Live | Org chart (colour-coded) + FOSSCell structure + wayfinding; engine on mermaid.js 10.9.4, `neutral` theme |
| SemanticResultFormats | ✅ | ⚠️ Partial | Cargo dynamic tables live (Centres, Clubs); SRF calendar pending Date-field schema |
| ExternalData | ✅ | ⚠️ Configured | Allowlist + 1h cache in ConfigMap (active next rollout); live feed deferred — NITC has no RSS/JSON |
| Translate | ✅ | ⚠️ Prepared | `Welcome` page translation-ready; awaits admin mark-for-translation |
| UniversalLanguageSelector | ✅ | 🟢 Live | Malayalam input + webfonts + interlanguage selector; `Help:Languages` |
| UploadWizard | ✅ | ⚠️ Configured | Not linked from nav; users use plain Special:Upload |
| SyntaxHighlight | ✅ | ⚠️ Rare | Few code blocks; tech wiki should use heavily |
| ReplaceText | ✅ | Admin tool | Use for category/naming migrations |
| TemplateData | ✅ | 🟢 Live | JSON param docs on 5 key infoboxes (VE + forms) |
| SemanticMediaWiki | ✅ | ❌ No | Installed but Cargo is the data layer — decide role |
| Cargo | ✅ | ✅ Yes | 8 tables; underused for queries/SRF |

---

## 2. Per-Extension Improvement Plans

### 2.1 Lingo — Auto-Glossary 🟢 Quick Win

**What it does:** Define terms once in `Terminology`; every occurrence across the wiki gets a hover tooltip. Zero per-page editing.

**Why it fits:** A tech/college wiki is dense with jargon — FOSS terms (GPL, copyleft, kernel), NITC terms (Rajpath, CCC, Tathva, B-batch), and acronyms (CCD, CITRA, SAC).

**Plan:**
1. Create page `Terminology` with definition-list syntax:
   ```
   ;FOSS
   :Free and Open Source Software — software that respects users' freedom to run, study, share and modify it.
   ;Rajpath
   :The main central pathway of NITC connecting the entrance to the Main Building.
   ;CCC
   :Central Computer Centre — the main computing facility at NITC.
   ;Copyleft
   :A licensing method that requires derivative works to be released under the same free terms.
   ```
2. Seed ~80–100 terms across 3 categories: FOSS/tech, NITC campus/culture, acronyms.
3. Configure `$wgexLingoDisplayOnce = true;` (tooltip on first occurrence per page) in LocalSettings.
4. Optionally restrict to mainspace to avoid noise in Talk/User pages.

**Effort:** 2–3 hrs to seed terms | **Impact:** Every article, instantly.

---

### 2.2 WikiSEO — Proper Metadata 🟢 Quick Win

**What it does:** Per-page control of `<title>`, meta description, OG tags, Twitter cards, JSON-LD, canonical URLs, robots directives.

**Current state:** LocalSettings has a hand-rolled `BeforePageDisplay` OG hook reading Description2 output. WikiSEO supersedes this with structured, per-page control.

**Plan:**
1. Bake `{{#seo:}}` into key infobox templates so metadata is automatic:
   - `Template:Infobox FOSSMeet` → `{{#seo:title={{{name}}}|description=...|image={{{image}}}|type=event}}`
   - `Template:Infobox Centre` → description from first paragraph
   - `Template:Infobox Club` → org schema
2. Add JSON-LD `type=Organization` / `type=Event` for rich Google results.
3. Add a `{{SEO}}` wrapper template so editors set keywords without learning syntax.
4. Retire the custom OG hook in LocalSettings once WikiSEO covers it (avoid duplicate tags).

**Effort:** 3–4 hrs | **Impact:** Better Google ranking + social previews for the whole site.

---

### 2.3 SemanticResultFormats + Cargo — Dynamic Views 🟡 High Value

**What it does:** Render query results as calendars, timelines, charts, galleries, maps instead of flat tables.

**Note on data layer:** We use **Cargo** as primary store. SRF formats work with SMW `#ask`. Two options:
- **(A)** Add lightweight SMW annotations alongside Cargo on key templates (Events, FOSSMeet) to unlock SRF calendar/timeline.
- **(B)** Use Cargo's own formats (`format=calendar`, `format=timeline`, `format=googlepie`) where available, reserve SRF for what Cargo lacks.

**Recommend (B) first** (no dual-annotation overhead), fall back to (A) for advanced charts.

**Plan / concrete views to build:**
| Page | View | Source |
|---|---|---|
| `Events` portal | Calendar of all events | Cargo `Events` table `format=calendar` |
| `FOSSMeet` hub | Timeline 2005→2026 | Cargo query on FOSSMeet editions |
| `Placement Reports` | Bar chart of avg salary by year | Cargo from CCD reports → `format=bar` |
| `Clubs` portal | Card gallery of all clubs | Cargo `Communities` `format=gallery` |
| Home Teams hub | Timeline of achievements | Cargo on Home Team Year |

**Prereq:** Add Cargo `#cargo_store` declarations to `Infobox Centre`, `Infobox Club`, `CCD Year Report`, `Infobox FOSSMeet` (most don't store yet).

**Effort:** 6–8 hrs | **Impact:** Portals become living dashboards.

---

### 2.4 Mermaid — Diagrams 🟡 High Value

**What it does:** Render flowcharts, timelines, org charts, Gantt, mind maps from text.

**Concrete uses:**
1. **NITC org chart** on `NITC Administration` — Director → Deans → HODs → Centres.
2. **FOSSMeet timeline** — Gantt/timeline of editions and milestones.
3. **Club structure** — team hierarchy on each club page (e.g. FOSSCell: Tech/Content/Design/Media/Event teams).
4. **Campus wayfinding** — simple node graph "Entrance → Rajpath → Centre Circle → Main Building".
5. **Academic flowcharts** — course prerequisite chains per department.
6. **Wiki governance** — the editorial workflow on the guidelines page.

**Plan:**
- Add a `{{Mermaid}}` helper/example page documenting syntax for editors.
- Seed the 6 diagrams above as first examples.

**Effort:** 4–5 hrs | **Impact:** Visual clarity on dense admin/structure pages.

---

### 2.5 Maps — Interactive Campus Map 🟡 High Value

**What it does:** Leaflet maps (configured, no API key) with markers, popups, GeoJSON overlays.

**Why it fits:** We have 100+ campus location pages (`Campus Networking Centre`, `Health Centre`, hostels, canteens) with **zero geographic context**.

**Plan:**
1. Add `coordinates` field usage to `Infobox Campus Location` (already has the field).
2. Create `NITC Campus Map` page with a full Leaflet map: markers for every location with `coordinates` set.
3. Per-location mini-map in the infobox via `{{#display_map:}}`.
4. Build a `GeoJson:NITC Campus` overlay (campus boundary, zones) in the `GeoJson` namespace.
5. Use Cargo to auto-populate markers: query all pages with coordinates → render on one map.

**Effort:** 5–6 hrs (mostly collecting coordinates) | **Impact:** Genuinely useful for freshers/visitors.

---

### 2.6 ExternalData — Live Data Feeds 🟠 Medium

**What it does:** Pull data from URLs (JSON/CSV/XML/HTML), other wikis, or databases into pages.

**Why it fits:** We manually copy-paste from nitc.ac.in (centres, placements, news). ExternalData can pull live.

**Concrete uses:**
1. **NITC news ticker** — `{{#get_web_data:}}` the NITC notifications feed → display latest on Main Page.
2. **Placement data** — if CCD publishes JSON, auto-refresh report stats.
3. **GitHub stats** — pull FOSSCell org repo stars/activity onto the FOSSCell page.
4. **Weather/events** — optional campus widgets.

**Caution:** Network egress from pods + cache TTL. Set `$wgExternalDataSources` allowlist (only nitc.ac.in, api.github.com). Respect `$edgCacheTable` for caching.

**Effort:** 4–6 hrs | **Impact:** Less manual maintenance, fresher data.

---

### 2.7 Widgets — Safe Third-Party Embeds 🟠 Medium

**What it does:** Reusable Smarty-templated embeds in the `Widget:` namespace. Safer than raw HTML.

**Concrete widgets to build:**
| `Widget:` | Use |
|---|---|
| `Widget:Instagram` | Embed club Instagram posts/feeds |
| `Widget:GoogleCalendar` | Embed the events calendar |
| `Widget:GitHubCard` | Repo card for project pages |
| `Widget:Spotify` | Podcast/music for cultural pages |
| `Widget:GoogleForm` | Registration forms for events |

**Note:** EmbedVideo already handles YouTube/Vimeo — don't duplicate. Widgets fills the gaps (Instagram, forms, calendars).

**Effort:** 3–4 hrs | **Impact:** Richer event/club pages without security risk.

---

### 2.8 Translate + UniversalLanguageSelector — Multilingual 🟠 Medium

**What it does:** Mark pages for translation; ULS provides language switcher + Malayalam fonts/input.

**Why it fits:** NITC is in Kerala. Key public-facing pages (Welcome, About NITC, FOSSMeet, fest pages) benefit from Malayalam.

**Plan (scoped — don't translate everything):**
1. Configure ULS: enable Malayalam (`ml`) input methods + webfonts.
2. Mark only **high-traffic public pages** for translation: `Main Page`, `WIKI FOSSCELL NITC:Welcome`, `NITC`, `FOSSMeet`, `Ragam`, `Tathva`.
3. Wrap translatable content in `<translate>` tags.
4. Add language bar to Main Page.

**Effort:** 4–5 hrs setup + ongoing translation | **Impact:** Accessibility for regional audience.

---

### 2.9 UploadWizard — Better Uploads 🟢 Quick Win

**What it does:** Multi-step guided upload with metadata, licensing, categories.

**Current:** Configured but users still hit plain `Special:Upload`.

**Plan:**
1. Add "Upload" link in Citizen skin nav → `Special:UploadWizard`.
2. Configure license options (CC-BY-SA default, NITC-owned, fair-use).
3. Auto-add `Category:Uploaded with UploadWizard` (already set) + prompt for descriptive categories.
4. Document in the editing guidelines.

**Effort:** 1–2 hrs | **Impact:** Better-tagged media library (178 images currently, mostly uncategorized).

---

### 2.10 SyntaxHighlight — Code Blocks 🟢 Quick Win

**Why it fits:** FOSSCell is a tech club. Workshop pages, project docs, and tutorials should show real code.

**Plan:**
1. Retrofit existing workshop/tutorial pages (Git workshop, install fest) with `<syntaxhighlight lang="bash">`.
2. Add a code-style guideline to the editing guide.
3. Create a `Help:Code formatting` page.

**Effort:** 2–3 hrs | **Impact:** Professional-looking technical content.

---

### 2.11 PageForms + PageSchemas + TemplateData — Complete the Forms 🟡 High Value

**Continues `pageforms-migration.md`.** Now add:
1. **TemplateData JSON** to every infobox → VisualEditor users get proper param editors + the forms get field metadata.
2. **PageSchemas** — define schema on category pages so forms + templates + Cargo stay in sync from one definition.
3. **Cargo autocomplete** in forms — `{{{field|chairperson|values from cargo=...}}}`.
4. Finish remaining forms: CCD Year Report, Course, Faculty, Campus Location, Event, FOSSMeet, SAC Meeting, Person.

**Effort:** ongoing (per `pageforms-migration.md` timeline) | **Impact:** Consistent structured data.

---

### 2.12 ReplaceText — Maintenance Tool 🟢 Use As-Needed

**Use for:**
- Finishing the category migration (`Category:Research Centres` cleanup already done manually — future ones via ReplaceText).
- Naming-convention fixes from ROADMAP Phase 5.
- Bulk link updates when pages are renamed/merged (migration.md).

**Effort:** minutes per operation | **Impact:** Saves hours of manual edits.

---

## 3. Sequenced Roadmap

### Sprint 1 — Quick Wins (Week 1) 🟢 — ✅ DONE
- [x] **Lingo:** seed `Terminology` (FOSS/NITC/centre/event terms) + LocalSettings config — *verified: 6 tooltips on FOSSCell*
- [x] **WikiSEO:** bake `{{#seo:}}` into Centre infobox; retire custom OG hook — *verified: clean OG tags, no duplicates*
- [x] **UploadWizard:** nav link (`$wgUploadNavigationUrl`) + license config
- [x] **SyntaxHighlight:** `Help:Code formatting` page + `{{SEO}}` helper template
- [ ] *Follow-up:* bake `{{#seo:}}` into remaining infoboxes (Club, FOSSMeet, Home Team); retrofit workshop pages with `<syntaxhighlight>`

### Sprint 2 — Visual & Structured (Week 2) 🟡 — ✅ DONE
- [x] **Mermaid:** org chart on `NITC Administration` (classDef colour-coding + legend), FOSSCell team structure, campus wayfinding on `Centre Circle`
- [x] **Mermaid engine:** upgraded extension ~4.0 → ~6.0 (mermaid.js 8.14.0 → 10.9.4); theme set to `neutral` for Citizen light/dark compatibility
- [x] **Cargo `#cargo_store`:** added to `Infobox Centre` (Centres, 34 pages) and `Infobox Club` (Clubs, 24 pages)
- [x] **Cargo dynamic views:** `Multidisciplinary Centres`, `Thematic Centres`, and `Clubs` directories auto-generate from Cargo
- [ ] *Follow-up:* FOSSMeet timeline (needs verified per-edition data); Cargo store on `CCD Year Report` + `Infobox FOSSMeet`; Events `format=calendar` needs a Date field on `Template:Event`

### Sprint 3 — Maps & Live Data (Week 3) 🟡🟠 — 🟢 In progress
- [x] **Maps:** built [[NITC Campus Map]] — Leaflet/OSM, auto-populating from Cargo `CampusLocations` table; 10 locations geocoded from OpenStreetMap (Overpass API); `Infobox Campus Location` now stores `coordinates` and shows an inline mini-map
- [x] **ExternalData:** security allowlist configured (nitc.ac.in, en.wikipedia.org, wikidata, api.github.com) + 1h cache. ConfigMap applied (takes effect next rollout). '''Live news ticker deferred''' — NITC exposes no stable JSON/RSS feed (all endpoints return HTML); scraping would be fragile.
- [ ] **Widgets:** deferred — the `Widget:` namespace is protected (`editwidgets` right); enabling needs a LocalSettings grant + rollout. `Widget:GoogleForm` drafted but not yet creatable.

> ⚠️ **Rollout hazard (✅ RESOLVED this sprint):** the per-pod `setupStore` `OPTIMIZE` deadlock that took the site to 502 is fixed via a flock-serialised `.setup-done` sentinel on a shared hostPath — see Risks. Rollouts are now clean (`maxSurge:1`, verified HTTP 200 throughout).

### Sprint 4 — Forms & i18n (Week 4) 🟡🟠 — ✅ DONE
- [x] **PageForms:** all 14 core forms live + category-linked (Centre, Club, Home Team, Home Team Year, Campus Location, Centre Year Report, CCD Year Report, Hostel, Course, Person, Faculty, Event, SAC Meeting, FOSSMeet). "Edit with form" tab verified.
- [x] **TemplateData:** JSON parameter docs on 5 key infoboxes (Centre, Club, Campus Location, Hostel, Faculty) — improves VisualEditor param editors + form metadata.
- [x] **ULS:** Universal Language Selector live (Malayalam input methods + webfonts + interlanguage selector). `Help:Languages` documents the workflow.
- [x] **Translate:** translation-ready `Welcome` page prepared with `<languages/>` + `<translate>` units; '''awaits an admin to "Mark for translation" via Special:PageTranslation''' (the edit API cannot perform that step).
- [ ] *Follow-up:* PageSchemas on top categories; Cargo autocomplete in forms; translate more public pages once the workflow is exercised.

---

## 4. LocalSettings Changes Needed

These config additions accompany the work above (apply to `localsettings-configmap.yaml`):

```php
## Lingo
$wgexLingoDisplayOnce = true;          # tooltip once per page
$wgexLingoUseNamespaces = [ NS_MAIN => true ];  # mainspace only

## WikiSEO — once baked into templates, retire custom OG hook
# (remove the BeforePageDisplay og: hook block to avoid duplicate tags)

## UniversalLanguageSelector
$wgULSIMEEnabled = true;
$wgULSWebfontsEnabled = true;

## Translate
$wgTranslateDocumentationLanguageCode = 'qqq';
$wgPageTranslationNamespace = 1198;    # Translations ns already exists

## ExternalData — security allowlist
$wgExternalDataSources['nitc'] = [ 'url' => 'https://nitc.ac.in/$1', 'allowed' => true ];
$wgExternalDataAllowGetters = [ 'web' ];
# cache external fetches in a Cargo/DB table, TTL 1h

## Maps
# already: $egMapsDefaultService = 'leaflet';
$egMapsLeafletLayers = [ 'OpenStreetMap' ];
```

---

## 5. Risks & Notes

- **SMW setupStore deadlock on rollout (✅ RESOLVED):** `setupStore` used to run on every pod boot; concurrent runs deadlocked on the `smw_*` `OPTIMIZE` table locks → 502. '''Fixed''' — `setupStore` now runs once, gated by a flock-serialised `.setup-done` sentinel on a shared kenobi hostPath (all pods + the maintenance Job mount it). Routine restarts skip `setupStore` entirely; a single bootstrap `OPTIMIZE` is ~4s (under the probe). The web container no longer runs `setupStore` (just `supervisord`), and the maintenance Job was repointed from the stale `mysql-pxc-db-haproxy.pxc-clusters` endpoint to the live `mysql-ram-pxc.pxc-ram`. Verified: clean rolling update (`maxSurge:1`), HTTP 200 throughout.
- **ConfigMap apply ≠ restart:** updating the ConfigMap does not restart pods; mounted config changes only take effect on the next pod restart. Safe to apply anytime; schedule the restart deliberately given the deadlock hazard above.

- **MW 1.45 `Html` class:** ✅ Resolved — 1.45 removed the global `Html` alias (now `MediaWiki\Html\Html`). Mermaid/Maps/SRF still `use Html;`. A `class_alias` shim in `localsettings-configmap.yaml` restores it for all 18+ affected files.

- **SMW vs Cargo overlap:** Both installed. Keep Cargo as primary data store; use SMW only where SRF needs it. Don't double-annotate everything — it doubles write load (relevant on the laptop cluster).
- **ExternalData egress:** Pods fetch external URLs → ensure NetworkPolicy allows egress to nitc.ac.in + cache aggressively (don't hammer on every parse).
- **WikiSEO duplicate tags:** ✅ Resolved — the hand-rolled OG hook was removed from `localsettings-configmap.yaml`; WikiSEO now owns all OG/Twitter tags with auto-description.
- **Lingo performance:** With 100+ terms, `displayOnce` + mainspace-only keeps parse cost down. Monitor parser cache.
- **Translate is sticky:** Once a page is marked `<translate>`, its edit workflow changes. Only mark stable, high-value pages.
- **Maps coordinates:** The bottleneck is collecting accurate lat/long for 100+ locations — crowdsource via a `Task Board` entry.

---

## 6. Definition of Done

- [ ] `Terminology` live with tooltips visible on articles
- [ ] `{{#seo:}}` emitting per-page metadata; custom OG hook removed
- [ ] ≥6 Mermaid diagrams on admin/structure/fest pages
- [ ] Events calendar + FOSSMeet timeline + placement chart rendering from Cargo
- [ ] `NITC Campus Map` with ≥30 located markers
- [ ] NITC news feed live on Main Page via ExternalData
- [ ] ≥3 Widgets in use on event/club pages
- [ ] All infoboxes have TemplateData JSON
- [ ] Main Page + 5 public pages translatable with ULS language bar
- [ ] UploadWizard linked in nav; new uploads categorized
