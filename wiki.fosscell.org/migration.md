# Year-Namespace Migration Plan — wiki.fosscell.org

> **Generated:** 2026-05-27  
> **Convention:** Recurring events live at `YYYY:EventName` (year namespace).  
> **Reference:** README.md § Page Naming, ADR-1 (Year namespaces over flat page names)

---

## Table of Contents

- [1. Current State](#1-current-state)
- [2. Pages Requiring Migration](#2-pages-requiring-migration)
  - [2.1 FOSSMeet (highest priority)](#21-fossmeet-highest-priority)
  - [2.2 Ragam](#22-ragam)
  - [2.3 Tathva](#23-tathva)
  - [2.4 FridayNightFOSS / FOSSCell Events](#24-fridaynightfoss--fosscell-events)
  - [2.5 Workshops & One-off Events with Year in Name](#25-workshops--one-off-events-with-year-in-name)
  - [2.6 Wiki Sprints & Challenges](#26-wiki-sprints--challenges)
  - [2.7 SAC Meetings (year-scoped)](#27-sac-meetings-year-scoped)
  - [2.8 Onam / Festival Events](#28-onam--festival-events)
  - [2.9 Convocation](#29-convocation)
  - [2.10 Legacy FOSSMeet Paths (Calicut/NIT/…)](#210-legacy-fossmeet-paths-calicutnit)
  - [2.11 NITC Mime Team (year editions already exist — verify main-ns duplicates)](#211-nitc-mime-team)
  - [2.12 Miscellaneous Year-Scoped Pages](#212-miscellaneous-year-scoped-pages)
- [3. Already Migrated (reference)](#3-already-migrated-reference)
- [4. Migration Procedure](#4-migration-procedure)
- [5. Redirect Policy](#5-redirect-policy)
- [6. Execution Order](#6-execution-order)
- [7. Verification Checklist](#7-verification-checklist)

---

## 1. Current State

### Year namespaces configured
`1961:` through `2028:` — all registered and functional.

### What's already in year namespaces (correctly placed)

| Namespace | Pages |
|-----------|-------|
| `2002:` | Ragam, Tathva |
| `2005:`–`2009:` | FOSSMeet (full set: /Coverage, /Gallery, /Roadmap, /Schedule, /Speakers, /Team), Ragam, Tathva |
| `2010:`–`2011:` | FOSSMeet (full set), NITC Mime Team, Ragam, Tathva |
| `2012:` | NITC Mime Team, Ragam, Tathva |
| `2013:`–`2014:` | FOSSMeet (full set), NITC Mime Team, Ragam, Tathva |
| `2015:` | NITC Mime Team, Ragam, Tathva |
| `2016:`–`2019:` | FOSSMeet (full set), NITC Mime Team, Ragam, Tathva |
| `2020:`–`2021:` | NITC Mime Team, Ragam, Tathva |
| `2022:` | NITC Mime Team, Ragam, Tathva |
| `2023:` | FOSSMeet (full set), NITC Mime Team, Ragam, Tathva |
| `2024:` | FOSSMeet (full set), NITC Mime Team, Ragam, Tathva |
| `2025:` | FOSSMeet (full set), NITC Mime Team, Ragam (full: /Competitions, /Coverage, /Gallery, /Performers, /Schedule, /Team), Tathva |
| `2026:` | FOSSCell, FOSSCell/Friday Night FOSS Jan'26, FOSSMeet (full set), LnD, LnD/Book Club, LnD/Book Club/January, Magazine, Magazine/Scrapbook, NITC Mime Team, Ragam (full set), Tathva |
| `2027:` | FOSSMeet, FOSSMeet/Roadmap *(only these two in main namespace)* |

### Problem: main namespace still has ~50+ pages that are year-specific editions of recurring events

---

## 2. Pages Requiring Migration

### 2.1 FOSSMeet (highest priority)

These are the **primary content pages** with significant view counts and edit history. They must become redirects to their year-namespace counterparts.

| Current Page (main namespace) | Target | Bytes | Views | Edits | Notes |
|-------------------------------|--------|-------|-------|-------|-------|
| `FOSSMEET 2005` | `2005:FOSSMeet` | 3,008 | 6,164 | 7 | Has infobox + content |
| `FOSSMEET 2006` | `2006:FOSSMeet` | 4,397 | 4,027 | 6 | Has infobox + content |
| `FOSSMEET 2007` | `2007:FOSSMeet` | 5,554 | 1,225 | 3 | Has infobox + content |
| `FOSSMEET 2008` | `2008:FOSSMeet` | 525 | 1,767 | 3 | Stub with infobox |
| `FOSSMEET 2009` | `2009:FOSSMeet` | 374 | 1,849 | 3 | Stub |
| `FOSSMEET 2010` | `2010:FOSSMeet` | 247 | 886 | 3 | Stub |
| `FOSSMeet 2011` | `2011:FOSSMeet` | 765 | 3,332 | 7 | Has infobox |
| `FOSSMeet 2013` | `2013:FOSSMeet` | 6,014 | 2,980 | 6 | Rich content + image |
| `FOSSMeet 2014` | `2014:FOSSMeet` | 3,823 | 3,105 | 7 | Has infobox |
| `FOSSMeet 2016` | `2016:FOSSMeet` | 310 | 2,804 | 7 | Stub |
| `FOSSMeet 2017` | `2017:FOSSMeet` | 537 | 4,057 | 8 | Has infobox + image |
| `FOSSMeet 2018` | `2018:FOSSMeet` | 729 | 3,283 | 7 | Has infobox + image |
| `FOSSMeet 2019` | `2019:FOSSMeet` | 308 | 1,961 | 6 | Stub |
| `FOSSMeet'23` | `2023:FOSSMeet` | 651 | 4,699 | 8 | Has infobox; 1 redirect points here |
| `FOSSMeet'24` | `2024:FOSSMeet` | 3,358 | 92,005 | 70 | **Highest traffic**; 1 redirect points here |
| `FOSSMeet'25` | `2025:FOSSMeet` | 2,985 | 11,003 | 17 | Has infobox; 1 redirect points here |
| `FOSSMeet 2005 Team` | `2005:FOSSMeet/Team` | 101 | 1,752 | 2 | Team subpage |
| `FOSSMeet/24 Success Party` | `2024:FOSSMeet/Success Party` | 359 | 2,000 | 2 | Event subpage |
| `FOSSMEET` (duplicate 1) | redirect → `FOSSMeet` | — | — | — | Likely already a redirect |
| `FLOSS Meet` | redirect → `FOSSMeet` | — | — | — | Historical alias |

**Also in main namespace (old wiki path format):**

| Current Page | Target | Notes |
|--------------|--------|-------|
| `Calicut/NIT/FOSS Meet` | redirect → `FOSSMeet` | 6,462 bytes; historical import from old wiki |
| `Calicut/NIT/FOSS Meet/05` | redirect → `2005:FOSSMeet` | Old subpage path |
| `Calicut/NIT/FOSS Meet/06` | redirect → `2006:FOSSMeet` | Old subpage path |
| `Calicut/NIT/FOSS Meet/07` | redirect → `2007:FOSSMeet` | Old subpage path |
| `FOSS Huts,FOSSMEET 2010` | `2010:FOSSMeet/FOSS Huts` | Subpage content |

### 2.2 Ragam

| Current Page | Target | Notes |
|--------------|--------|-------|
| `Ragam` (main) | Keep as **umbrella** page | NOT migrated — this is the recurring-event overview |
| `Ragam'25 Controversies and Alleged Saffronisation at NIT Calicut` | `2025:Ragam/Controversies` | 5,978 bytes; year-specific incident |

### 2.3 Tathva

| Current Page | Target | Notes |
|--------------|--------|-------|
| `Tathva` (main) | Keep as **umbrella** page | NOT migrated |
| `Tathva'24` | `2024:Tathva` | 3,716 bytes; year edition |
| `Tathva Council` | Keep in main namespace | Perennial org body |
| `Tathva convener` | Keep in main namespace | Role description |
| `Tathva Lecture` | Keep in main namespace | Recurring series overview |
| `Committees in Tathva '24` | `2024:Tathva/Committees` | Year-specific |
| `Teams and Committees in Tathva'24` | `2024:Tathva/Teams` | Year-specific |
| `Teams in Tathva'24` | `2024:Tathva/Teams` | Duplicate — merge then redirect |

### 2.4 FridayNightFOSS / FOSSCell Events

| Current Page | Target | Notes |
|--------------|--------|-------|
| `FridayNightFOSS` | Keep as **umbrella** page | Series overview |
| `Friday Night FOSS Aug'23` | `2023:FOSSCell/Friday Night FOSS Aug` | Year-specific edition |
| `Friday Night FOSS Oct'24` | `2024:FOSSCell/Friday Night FOSS Oct` | 1,898 bytes |
| `Friday Night Foss Aug 30th,2024` | `2024:FOSSCell/Friday Night FOSS Aug` | Duplicate? Merge with above or make separate |
| `Godot workshop 2025` | `2025:FOSSCell/Godot Workshop` | Year-specific workshop |
| `Debian Day 2025` | `2025:FOSSCell/Debian Day` | 6,760 bytes; one-off event |
| `GNU-Linux install Fest (B24) Aug 31,2024` | `2024:FOSSCell/GNU-Linux Install Fest` | Year-specific |
| `Nix flakes for Labs` | Evaluate — likely `2025:FOSSCell/Nix Flakes Workshop` or keep if evergreen | Check content |
| `Self-Hosting 101` | Keep (evergreen tutorial) | Not year-specific |
| `FastAPI Workshop` | Keep (evergreen) | Not year-specific |
| `Git Workshop` | Keep (evergreen) | Not year-specific |
| `Rust Workshop` | Keep (evergreen) | Not year-specific |
| `Godot Workshop` | Keep as umbrella | Not year-specific |
| `LaTeX 101` | Keep (evergreen) | Not year-specific |
| `LLM101 : Beginner session on LLM` | Evaluate year | Check if this was a one-off |

### 2.5 Workshops & One-off Events with Year in Name

| Current Page | Target | Notes |
|--------------|--------|-------|
| `BLS Workshop 2018` | `2018:BLS Workshop` | 1,009 bytes; one-time event |
| `Tracercon` | Evaluate | Could be year-scoped if it's an edition |
| `CodeInit` | Keep (series overview) | — |
| `Hello Noobies` | Keep (series overview) | — |
| `Sprint24` | `2024:FOSSCell/Sprint` | 179 bytes; year-specific |
| `Back to Campus Wiki Marathon` | Keep as umbrella | Recurring concept |
| `2025 edit streak challenge` | `2025:Wiki Edit Streak Challenge` | Year-specific |

### 2.6 Wiki Sprints & Challenges

| Current Page | Target | Notes |
|--------------|--------|-------|
| `Wiki Sprint Jan2024` | `2024:Wiki Sprint` | 1,413 bytes; 52,695 views! |
| `Find My Wiki Challenge` | Evaluate year | Check if single edition |
| `Back to Campus Wiki Marathon Goals page` | Year-scope if dated | Check content |

### 2.7 SAC Meetings (year-scoped)

These are meeting agendas/minutes with explicit dates. Convention: `YYYY:SAC/Meeting-NN` or keep in main with `{{Infobox SAC Meeting}}`. Given the volume, recommend **keeping in main namespace** but properly categorized with `[[Category:SAC Meetings YYYY]]`. Only migrate if they follow recurring-event pattern.

| Current Page | Proposed Action |
|--------------|-----------------|
| `Agenda RM 01 7/12/21 at 6` | `2021:SAC/RM-01` |
| `Agenda RM 01 7/12/21 at 6 minutes` | `2021:SAC/RM-01 Minutes` |
| `Agenda RM 02 18.12.2021` | `2021:SAC/RM-02` |
| `Minutes RM 02 18.12.2021` | `2021:SAC/RM-02 Minutes` |
| `Agenda of SAC RM-02 (15/06/2022)` | `2022:SAC/RM-02` |
| `Agenda of SAC RM-03 (04/08/2022)` | `2022:SAC/RM-03` |
| `Agenda of SAC RM-03 (13/02/2022)` | `2022:SAC/RM-03b` |
| `Agenda of SAC RM-04 (04/04/2022) SAC 2021-22` | `2022:SAC/RM-04` |
| `Agenda of SAC RM-04 (04/11/2022)` | `2022:SAC/RM-04b` |
| `Agenda of SAC RM-06 (20/02/2023)` | `2023:SAC/RM-06` |
| `Agenda of SAC RM-07 (07/03/2023)` | `2023:SAC/RM-07` |
| `Agenda of SAC RM-08 (30/03/2023)` | `2023:SAC/RM-08` |
| `Minutes of SAC EM-01 (09/01/2022)` | `2022:SAC/EM-01 Minutes` |
| `Minutes of SAC EM-04 (07/03/2022)` | `2022:SAC/EM-04 Minutes` |
| `Minutes of SAC RM-01 (15/05/2022)` | `2022:SAC/RM-01 Minutes` |
| `Minutes of SAC RM-03 (13/02/2022)` | `2022:SAC/RM-03 Minutes` |
| `Minutes of the Meeting With DSW 19/01/2022 SAC 2021-22` | `2022:SAC/DSW Meeting Jan` |
| `RM-01 NOV 6 2023` | `2023:SAC/RM-01` |
| `RM-02 Jan 5 2024` | `2024:SAC/RM-02` |
| `Meeting with DSW-1 NOV 25th 2023` | `2023:SAC/DSW Meeting Nov` |
| `Meeting with director Nov 14th 2023` | `2023:SAC/Director Meeting Nov` |
| `SAC 2013 RM agenda` | `2013:SAC/RM Agenda` |
| `SAC 2014 RM agenda` | `2014:SAC/RM Agenda` |
| `SAC Meeting Minutes - Attachment 2014` | `2014:SAC/Meeting Minutes Attachment` |
| `INTERIM SAC REPORT 2014` | `2014:SAC/Interim Report` |
| `First SAC Meeting Agenda - 21.07.2014` | `2014:SAC/RM-01` |
| `First SAC Meeting Agenda - 21.07.2014.docx` | Delete (file extension in title) |
| `Minutes for 21-07-14` | `2014:SAC/RM-01 Minutes` |
| `Minutes of 10-11-2014` | `2014:SAC/Meeting Nov Minutes` |
| `MINUTES OF THE GENERAL BODY MEETING...5th NOVEMBER 2013` | `2013:SAC/GBM Nov Minutes` |
| `MINUTES OF THE THIRD SAC MEETING` | Evaluate year | Needs date check |
| `GBM-06-05-2016` | `2016:SAC/GBM May` |
| `GBM-07-01-2016` | `2016:SAC/GBM Jan` |
| `GBM-08-10-2015` | `2015:SAC/GBM Oct` |
| `GBM 26-10-16` | `2016:SAC/GBM Oct` |
| `Even Semester Elections proposal` | Keep (policy page) | — |
| `Final Years in the Electorate SAC 2021-22` | `2022:SAC/Final Years Electorate` |
| `Mag Com Article SAC 2021-22` | `2022:SAC/MagCom Article` |
| `Akshaya sac 18-19` | `2019:SAC/Akshaya Report` |
| `ACIVEMENTS SAC 2018` | `2018:SAC/Achievements` |

### 2.8 Onam / Festival Events

| Current Page | Target | Notes |
|--------------|--------|-------|
| `SAC Onam` | Keep as umbrella OR evaluate year | Check content |
| `O(n)am - (CSE onam 2024)` | `2024:CSE Onam` | Year-specific |
| `ECE Onam` | Evaluate year | Check if specific edition |
| `NITC Diwali` | Keep (umbrella for recurring) | — |
| `NITC Holi` | Keep (umbrella for recurring) | — |
| `Pongal` | Keep (umbrella for recurring) | — |

### 2.9 Convocation

| Current Page | Target | Notes |
|--------------|--------|-------|
| `Convocation` | Keep as umbrella | Overview of convocation ceremonies |

### 2.10 Legacy FOSSMeet Paths (Calicut/NIT/…)

| Current Page | Target | Notes |
|--------------|--------|-------|
| `Calicut/NIT/FOSS Meet` | redirect → `FOSSMeet` | 6,462 bytes; imported content should merge into `FOSSMeet` |
| `Calicut/NIT/FOSS Meet/05` | redirect → `2005:FOSSMeet` | — |
| `Calicut/NIT/FOSS Meet/06` | redirect → `2006:FOSSMeet` | — |
| `Calicut/NIT/FOSS Meet/07` | redirect → `2007:FOSSMeet` | — |

### 2.11 NITC Mime Team

Year-namespace pages already exist (`2009:`–`2026:`). Check if there are main-namespace duplicates:

| Current Page | Target | Notes |
|--------------|--------|-------|
| `NITC Mime Team` | Keep as umbrella | Overview page |
| `NITC Mime Team B19` | `2019:NITC Mime Team` or subpage | Year-specific batch |

### 2.12 Miscellaneous Year-Scoped Pages

| Current Page | Target | Notes |
|--------------|--------|-------|
| `SPDC guidelines 2023-2024` | `2024:SPDC Guidelines` | Academic-year scoped |
| `Medi-claim Insurance Policy for the year 2018-19` | `2019:Medi-claim Insurance Policy` | Year-specific |
| `Academic plan1 20th April With quarantine` | `2020:Academic Plan` | COVID-era, year-specific |
| `Wonderful wheather ! FLOSS Meet a grand success` | redirect → `2007:FOSSMeet` or `2008:FOSSMeet` | Blog-style; check which year |
| `FOSS Huts,FOSSMEET 2010` | `2010:FOSSMeet/FOSS Huts` | Subpage of 2010 edition |
| `FOSSMeet CheckList` | Keep (perennial process doc) | — |
| `FOSSMeet Video Team` | Keep (perennial team info) | — |
| `FOSSMeet speakers` | Keep or make era-based | General speaker list |
| `ROBOWAR` | Evaluate year | May be year-specific |
| `Sulaimani Night` | Evaluate year | May be year-specific |
| `Summer With S8N` | Evaluate year | — |
| `NSL (NITC Super League)` | Evaluate year | May be year-specific edition |
| `Blood Donation` | Keep (recurring umbrella) | — |
| `Freshers Night` | Keep (recurring umbrella) | — |
| `Farewell` | Keep (recurring umbrella) | — |
| `Inter Department Men's Football` | Keep (recurring umbrella) | — |
| `Inter Department Women's Football` | Keep (recurring umbrella) | — |

---

## 3. Already Migrated (reference)

These pages already exist in the correct `YYYY:` namespace and are the **canonical** locations. The main-namespace duplicates (§2.1–2.3) should redirect here after content is verified as merged.

### FOSSMeet — Full set (2005–2026)
- `YYYY:FOSSMeet` + subpages `/Coverage`, `/Gallery`, `/Roadmap`, `/Schedule`, `/Speakers`, `/Team`
- Years with full subpages: 2005–2011, 2013–2014, 2016–2019, 2023–2026
- 2027 has stub only (`2027:FOSSMeet`, `2027:FOSSMeet/Roadmap`)

### Ragam — All years (2002–2026)
- `YYYY:Ragam` exists for 2002, 2005–2026
- 2025+ has subpages: `/Competitions`, `/Coverage`, `/Gallery`, `/Performers`, `/Schedule`, `/Team`

### Tathva — All years (2002–2026)
- `YYYY:Tathva` exists for 2002, 2005–2026

### NITC Mime Team — (2009–2026)
- `YYYY:NITC Mime Team` exists

---

## 4. Migration Procedure

For each page listed in §2:

### Step 1: Content Audit
1. Open the main-namespace page
2. Compare with the target year-namespace page (if it exists)
3. Determine:
   - If year-namespace page **already has the content** → main page becomes redirect
   - If year-namespace page is a **stub** and main page has richer content → merge content INTO year-namespace page, then redirect
   - If year-namespace page **doesn't exist** → move page to year namespace

### Step 2: Move or Merge
- **Move** (preferred): Use `Special:MovePage` — preserves edit history
  - Check "Leave a redirect behind" = YES
- **Merge** (when both exist): Copy unique content from main → year namespace, then replace main with `#REDIRECT [[YYYY:PageName]]`

### Step 3: Fix Links
- Use `Special:WhatLinksHere/OldPageName` to find all pages linking to the old title
- Update links to point to `[[YYYY:PageName]]` or rely on the redirect

### Step 4: Categories
- Ensure year-namespace page has proper categories:
  - `[[Category:FOSSMeet YYYY]]` (or `Ragam YYYY`, `Tathva YYYY`)
  - `[[Category:Events]]`
- Remove categories from redirect pages

---

## 5. Redirect Policy

- **Always leave a redirect** at the old location after moving
- Redirects use: `#REDIRECT [[YYYY:PageName]]`
- Suppress `{{DISPLAYTITLE}}` on redirect pages
- Add `[[Category:Redirects from legacy naming]]` to all migration redirects
- **Do NOT delete** old pages — they have view counts, backlinks, and search engine history

---

## 6. Execution Order

### Phase A — FOSSMeet (critical path)
**~20 pages.** These have the highest traffic and most naming inconsistency.

1. Verify content parity between main-ns and year-ns pages for each year
2. Merge any unique content from main → year namespace
3. Replace main-ns pages with redirects
4. Update `{{FOSSMeet Navbox}}` to link to year-namespace pages
5. Update `FOSSMeet` umbrella page links

### Phase B — Tathva & Ragam year editions
**~5 pages.** Lower volume but important for consistency.

1. Move `Tathva'24` → verify `2024:Tathva`
2. Move Ragam'25 controversy page → `2025:Ragam/Controversies`
3. Move Tathva'24 committee pages → `2024:Tathva/…`

### Phase C — FOSSCell Events (FridayNightFOSS, workshops)
**~8 pages.** Newer content, active community.

1. Move Friday Night FOSS dated editions to `YYYY:FOSSCell/…`
2. Move year-specific workshops (Godot 2025, Debian Day 2025, etc.)
3. Move `Sprint24` → `2024:FOSSCell/Sprint`

### Phase D — SAC Meetings
**~35 pages.** High volume, low individual importance.

1. Batch-move all SAC agendas/minutes to `YYYY:SAC/…`
2. Create `SAC` umbrella page if it doesn't link them properly
3. Delete the `.docx` titled page

### Phase E — Legacy Paths & Miscellaneous
**~10 pages.** Cleanup tier.

1. Redirect `Calicut/NIT/FOSS Meet/*` paths
2. Move remaining year-specific pages (BLS Workshop, SPDC, etc.)
3. Evaluate ambiguous pages (ROBOWAR, Sulaimani Night, etc.)

### Phase F — Wiki Sprint & Challenge pages
**~3 pages.**

1. Move `Wiki Sprint Jan2024` → `2024:Wiki Sprint`
2. Move `2025 edit streak challenge` → `2025:Wiki Edit Streak Challenge`

---

## 7. Verification Checklist

After migration is complete:

- [ ] **Zero year-specific event pages in main namespace** (except umbrella/overview pages)
- [ ] **All old URLs still work** (redirects in place)
- [ ] **Navboxes updated** (`{{FOSSMeet Navbox}}`, future `{{Ragam Navbox}}`, `{{Tathva Navbox}}`)
- [ ] **Search still finds content** (CirrusSearch indexes redirects)
- [ ] **Categories correct** — year-namespace pages categorized, redirects not
- [ ] **No double redirects** — run `Special:DoubleRedirects` after each phase
- [ ] **Infoboxes intact** — `{{Infobox FOSSMeet}}` renders correctly in year namespace
- [ ] **Cargo tables still populated** — Event template stores work across namespaces
- [ ] **View counters preserved** — note: moves via `Special:MovePage` preserve page ID

---

## Summary Statistics

| Category | Pages to migrate | Priority |
|----------|-----------------|----------|
| FOSSMeet editions | ~20 | 🔴 Critical |
| Tathva/Ragam editions | ~5 | 🟠 High |
| FOSSCell/FNF events | ~8 | 🟡 Medium |
| SAC Meetings | ~35 | 🟡 Medium |
| Legacy paths | ~5 | 🟢 Low |
| Workshops/misc | ~8 | 🟢 Low |
| **Total** | **~81 pages** | — |

---

## Notes

1. **`2027:FOSSMeet`** already exists in the year namespace but is also listed as `2027:FOSSMeet` in the main namespace AllPages listing — this appears to be correctly placed already.
2. **`FOSSMeet'24`** has 92,005 page views — the redirect MUST work perfectly. Consider keeping this page hot in search via `{{DISPLAYTITLE}}` on the redirect.
3. **SAC meetings** could alternatively stay in main namespace with proper categorization (`[[Category:SAC Meetings 2022]]`). The year-namespace move is optional but recommended for consistency. Discuss with admins before executing Phase D.
4. **Content pages with 0 bytes** (like `FOSSMeet'2024` which was never created) should NOT be migrated — they don't exist.
5. Some "FOSSMeet" pages are duplicates/redirects of each other (e.g., `FOSSMEET` → `FOSSMeet`). Consolidate the redirect chain to point to `FOSSMeet` (umbrella) or the appropriate `YYYY:FOSSMeet`.
