# wiki.fosscell.org — Progress Log

Track of all structural changes made to the wiki. Newest entries first.

---

## 2026-05-20 — Templates, Magazine, Task Board, Feature Activation

### What was done

**Templates & Systems Created:**

| Template/System | Purpose | Cargo Table | Status |
|---|---|---|---|
| `Template:Event` | Tag pages for "This Day in History" + Upcoming Events | `Events` | ✅ Live |
| `Template:This day in history` | Dynamic main page widget | — | ✅ Live |
| `Template:Upcoming events` | Dynamic main page widget | — | ✅ Live |
| `Template:Campaign` | Reusable promotional banner | — | ✅ Live |
| `Template:Nav Tiles` | Icon-tile grid navigation (Star Citizen Wiki style) | — | ✅ Live |
| `Template:Main Page Section` | Consistent section styling | — | ✅ Live |
| `Template:Quick Links` | Link bar widget | — | ✅ Live |
| `Template:Featured Article` | Featured content card | — | ✅ Live |
| `Template:Recent Activity` | Recent changes widget | — | ✅ Live |
| `Template:Book Club Meeting` | Living document for monthly reading circles | `BookClubMeetings` | ✅ Live |
| `Template:Magazine Submission` | Tag User: pages as magazine entries | `MagazineSubmissions` | ✅ Live |
| `Template:Magazine Entry Card` | Renders entries in magazine layout | — | ✅ Live |
| `Template:FOSSCell Activity` | Members log contributions to events | `FOSSCellActivities` | ✅ Live |
| `Template:FOSSCell Activity Card` | Renders activity in yearly report | — | ✅ Live |
| `Template:FOSSCell Event` | Define a FOSSCell event (members attach to it) | `FOSSCellEvents` | ✅ Live |
| `Template:FOSSCell Event Card` | Renders events in yearly report | — | ✅ Live |
| `Template:Task` | Wiki task tracking (kanban) | `WikiTasks` | ✅ Live |
| `Template:Task Card` | Renders tasks on board | — | ✅ Live |
| `Template:Community` | Organic interest groups (no hierarchy) | `Communities` | ✅ Live |
| `Template:LnD Navbox` | Navigation footer for LnD pages | — | ✅ Live |
| `Template:Whos Online` | Active users widget (MW 1.45 compat issue) | — | ⚠️ Blocked |

**Year-Namespace Pages Created:**

| Page | Purpose |
|---|---|
| `2026:LnD` | Literary and Debating Club 2026 overview |
| `2026:LnD/Book Club` | 2026 Book Club meetings index |
| `2026:LnD/Book Club/January` | Sample meeting page (skeleton) |
| `2026:Magazine` | The Minimum Viable Magazine — dynamic compilation |
| `2026:FOSSCell` | FOSSCell 2026 yearly report (event-based) |
| `2025:FOSSMeet` through `2005:FOSSMeet` | Event template on all canonical pages |

**Helper/Creation Pages:**

| Page | Purpose |
|---|---|
| `WIKI FOSSCELL NITC:Welcome` | Comprehensive onboarding guide |
| `WIKI FOSSCELL NITC:Create an event` | Event creation with InputBox |
| `WIKI FOSSCELL NITC:Submit to the Magazine` | Per-type InputBoxes for magazine submissions |
| `WIKI FOSSCELL NITC:Log FOSSCell Activity` | Per-type InputBoxes for activity logging |
| `WIKI FOSSCELL NITC:Create FOSSCell Event` | Event page creation form |
| `WIKI FOSSCELL NITC:Create a Book Club meeting` | Book Club meeting creation form |
| `WIKI FOSSCELL NITC:Task Board` | Kanban-style task board (Open/In Progress/Review/Done) |
| `WIKI FOSSCELL NITC:Create Task` | Task creation with InputBox |
| `WIKI FOSSCELL NITC:Browse by Category` | Interactive CategoryTree browser |
| `WIKI FOSSCELL NITC:User Profile Guide` | Profile setup instructions |
| `WIKI FOSSCELL NITC:Event creation guide` | Edit intro for event pages |

**Extensions Activated (were installed but unused):**

| Extension | What we did |
|---|---|
| InputBox | Enabled in LocalSettings, used in all creation forms |
| AJAXPoll | Created `Help:Polls` with docs + live demo |
| EmbedVideo | Created `Help:Embedding Videos` with docs |
| VoteNY | Created `Help:Page Ratings` with docs |
| BlogPage | Created `Help:Blogging` with InputBox form |
| RSS | Created `Help:RSS Feeds` with docs |
| SocialProfile + SystemGifts | Created milestone awards (First Edit → Veteran) + User Profile Guide |
| CategoryTree | Created Browse by Category page |
| TemplateStyles | Created `Template:Nav Tiles/styles.css` + `Help:TemplateStyles` |
| HitCounters | Used for Trending Pages on Main Page |
| ContributionScores | Linked from Nav Tiles |

**Infrastructure Fixes:**

| Fix | Detail |
|---|---|
| File cache disabled | `$wgUseFileCache = false` — Redis parser cache sufficient |
| Real IP detection | `$wgUsePrivateIPs + $wgCdnServersNoPurge` (Traefik + Cloudflare) |
| Traefik forwarded headers | `forwardedHeaders.trustedIPs` for k3s pod network |
| Anubis bot policy | Social crawlers (FB, Twitter, Discord, etc.) bypass challenge |
| Anubis API bypass | `/api.php` and `/rest.php` pass through without challenge |
| OpenGraph tags | Fixed: reads real page description from Description2, PageImages for images |
| WhosOnline table | Converted from MEMORY to InnoDB (Galera GTID compat) |
| Ghost DB | Reverted from ProxySQL to direct PXC HAProxy |

**Main Page:**
- Redesigned with hero quote, campaign banner, 10-tile navigation grid
- Sections: This Day in History, Featured, Upcoming Events, Trending Pages, Stats, Get Involved, Quick Links, Recent Activity
- Campaign banner promoting The Minimum Viable Magazine

**Sidebar (MediaWiki:Sidebar):**
- 6 sections: Navigation, Campus Life, Events, Create, Wiki, Help
- 35+ links covering all major areas

**Existing Page Migrations:**
- `GLUG NITC` → migrated from `{{Infobox Club}}` to `{{Community}}`
- `Literary and Debating Club` → added activities table, year archive, navbox
- `Book club` → added meeting archive, workflow explanation, navbox
- `FOSSMeet'26`, `FOSSMeet'25`, etc. → `{{Event}}` on canonical year-namespace pages
- `Founding of NIT Calicut` → `{{Event}}` for This Day in History

---

## Roadmap Status (cross-referenced with ROADMAP.md)

### Phase 1 — Spam Cleanup
- [ ] Block 3 sleeper accounts (DeniseHaber5, FlorrieColleano, Rae57A1886121)
- [x] CAPTCHA configured (QuestyCaptcha active)
- [x] Email restriction (@nitc.ac.in only)
- [x] AbuseFilter extension loaded

### Phase 2 — Duplicate Resolution
- [ ] Fix 3 wrong redirects (Discrete mathematics-1, Class Representatives, Broasted restaurant)
- [ ] Create 11 simple redirects
- [ ] 7 content merges
- [x] FOSSMeet namespace redirects (FOSSMeet'26 → 2026:FOSSMeet etc.)

### Phase 3 — Category Overhaul
- [ ] Delete 14 junk categories
- [ ] Rename 4 categories
- [x] Some new categories created (Communities, Magazine, Literary and Debating Club, Book Club, FOSSCell, Wiki Maintenance)
- [ ] Create remaining ~15 new categories from proposed tree
- [ ] Mass-tag 257 uncategorized pages

### Phase 4 — Template System
- [x] `{{Infobox FOSSMeet}}` ✅
- [x] `{{Infobox Club}}` ✅ (existed, in use)
- [ ] `{{Infobox SAC Meeting}}` — NOT CREATED
- [ ] `{{Infobox Course}}` — NOT CREATED
- [ ] `{{Infobox Person}}` — NOT CREATED
- [ ] `{{Infobox Faculty}}` — NOT CREATED
- [ ] `{{Infobox Hostel}}` — NOT CREATED
- [ ] `{{Infobox Campus Location}}` — NOT CREATED
- [x] `{{Community}}` ✅ (new, not in original roadmap)
- [x] `{{Event}}` ✅ (new, not in original roadmap)
- [x] `{{Book Club Meeting}}` ✅ (new, not in original roadmap)
- [x] `{{Magazine Submission}}` ✅ (new, not in original roadmap)
- [x] `{{FOSSCell Activity}}` ✅ (new, not in original roadmap)
- [x] `{{FOSSCell Event}}` ✅ (new, not in original roadmap)
- [x] `{{Task}}` ✅ (new, not in original roadmap)
- [x] `{{Campaign}}` ✅ (new, not in original roadmap)
- [x] `{{Nav Tiles}}` ✅ (new, not in original roadmap)

### Phase 5 — Naming Conventions
- [x] Year namespace convention established and documented (Welcome page)
- [x] User namespace convention for Magazine/Activity
- [ ] Formal naming conventions page (not yet a standalone doc)

### Phase 6 — Ongoing Governance
- [x] `WIKI FOSSCELL NITC:Welcome` (onboarding/guidelines)
- [x] `WIKI FOSSCELL NITC:Task Board` (task tracking)
- [ ] Stub policy page
- [ ] Review cadence documentation

---

## Remaining High-Priority Work

### Templates still needed (from original roadmap):
1. `{{Infobox Person}}` — for speakers, notable people, alumni (~50 pages)
2. `{{Infobox Hostel}}` — for 15+ hostel pages
3. `{{Infobox Campus Location}}` — for 80+ campus place pages
4. `{{Infobox Course}}` — for 40+ course pages
5. `{{Infobox Faculty}}` — for 20+ faculty pages
6. `{{Infobox SAC Meeting}}` — for 30+ minutes pages

### Content work:
1. Mass-categorize 257 uncategorized pages
2. Fix wrong redirects (3 pages)
3. Content merges (7 pairs)
4. Block 3 spam accounts
5. Delete 14 junk categories
6. Backfill FOSSMeet historical editions with infobox data
7. Create Ragam/Tathva year-namespace pages

---

## 2026-05-17 — FOSSMeet Template System & Namespace Migration

(Previous entry — see below)

### What was done

**Year-based namespaces (Wikimania-style):**
- Added to `LocalSettings.php`: dynamic namespace loop `1961` → `currentYear + 2`
- Every year gets a content + talk namespace pair (IDs 3000+)
- Subpages enabled, default search included, CirrusSearch indexed
- Academic planning gets 2 years ahead (2028 available today)

**Templates created/updated:**

| Template | Purpose | Status |
|---|---|---|
| `Template:Infobox FOSSMeet` | 40+ field infobox | ✅ Live |
| `Template:FOSSMeet Tabs` | Top portal bar | ✅ Live |
| `Template:FOSSMeet Navbox` | Bottom nav all editions | ✅ Live |

**Pages created in `2026:` namespace:**
- `2026:FOSSMeet` + Schedule, Speakers, Team, Roadmap, Gallery, Coverage

**Pages created in `2027:` namespace:**
- `2027:FOSSMeet` + Roadmap (planning tracker)

---

## Architecture Decisions

### ADR-1: Year namespaces over flat page names
- **Decision:** Use MediaWiki custom namespaces (`2026:FOSSMeet`) instead of flat titles
- **Reason:** Scoped search, AllPages filtering, magic words, per-namespace protection

### ADR-2: HTML `<tr>` over wikitext `|-` in templates
- **Decision:** All infobox templates use raw HTML table rows inside `{{#if:}}` blocks
- **Reason:** Wikitext `|-` inside parser functions is unreliably parsed

### ADR-3: Dedicated job runner sidecar
- **Decision:** Add a `jobrunner` sidecar container
- **Reason:** Low-traffic wiki accumulates thousands of queued jobs

### ADR-4: Roadmap as a subpage
- **Decision:** Every event edition gets a `/Roadmap` subpage

### ADR-5: User namespace for member contributions
- **Decision:** Magazine entries and activity logs live in `User:Name/Magazine/...` and `User:Name/FOSSCell/...`
- **Reason:** Users own their content, can edit anytime. Aggregation pages compile from Cargo dynamically.

### ADR-6: Events defined once, contributions attached
- **Decision:** FOSSCell events are single pages (`2026:FOSSCell/Event Name`). Members log contributions referencing the event.
- **Reason:** Prevents duplication — 10 people working on one event don't create 10 event entries.

### ADR-7: Organic communities vs formal clubs
- **Decision:** `{{Community}}` template for interest groups, `{{Infobox Club}}` for formal clubs
- **Reason:** Different governance models need different documentation patterns. Communities emphasize the talk page.
