# WikiRoadmap.md — wiki.fosscell.org Cleanup & Structuring Plan

> **Status:** In progress — Phase 4 (Templates) partially complete
> **Wiki:** https://wiki.fosscell.org — WIKI FOSSCELL NITC
> **Generated:** 2026-05-17 from a full audit of pages, users, categories, and content structure.
> **Last updated:** 2026-05-17 — FOSSMeet template system deployed, namespace migration started.

---

## Table of Contents

1. [Current State Summary](#1-current-state-summary)
2. [Phase 1 — Spam Cleanup](#2-phase-1--spam-cleanup)
3. [Phase 2 — Duplicate Resolution](#3-phase-2--duplicate-resolution)
4. [Phase 3 — Category Overhaul](#4-phase-3--category-overhaul)
5. [Phase 4 — Template System](#5-phase-4--template-system)
6. [Phase 5 — Naming Conventions](#6-phase-5--naming-conventions)
7. [Phase 6 — Ongoing Governance](#7-phase-6--ongoing-governance)
8. [Appendix: Full Duplicate Map](#appendix-a-full-duplicate-map)
9. [Appendix: Proposed Category Tree](#appendix-b-proposed-category-tree)
10. [Appendix: Template Specifications](#appendix-c-template-specifications)

---

## 1. Current State Summary

| Metric               | Count       | Notes                                    |
|-----------------------|-------------|------------------------------------------|
| Total pages           | 1,090       | All namespaces                           |
| Content articles      | 274         | Mainspace only                           |
| Total edits           | 2,643       |                                          |
| Uploaded files/images | 177         |                                          |
| Registered users      | 212         |                                          |
| Active users (30d)    | 3           | Afr4z, Maintenance script, Vysakh        |
| Admins                | 14          |                                          |
| Categories            | 39          | Only ~12 have any real members           |
| Categorized pages     | ~17 (6.2%)  | **93.8% of articles are uncategorized**  |
| Templates in use      | 1           | `{{Foss-meet-at-nitc}}` (nav footer)     |
| Infobox templates     | 0           | None exist                               |

### Key Problems

1. **Spam accounts** — A June 2024 bot wave registered ~33 accounts; 3 sleeper accounts remain unblocked.
2. **Duplicate pages** — 20+ groups of duplicate/overlapping pages, including wrong redirects.
3. **No category system** — 94% of pages are uncategorized. `Category:Places in NITC` has 0 members despite 100+ place pages existing.
4. **No templates** — Every page is freeform wikitext. No infoboxes, no standardized sections, no structured metadata.
5. **Inconsistent naming** — Same content under different capitalizations, abbreviations, and formats.
6. **Stale content** — Meeting minutes from 2013–2022 with no standard format.

---

## 2. Phase 1 — Spam Cleanup

**Effort:** ~30 minutes | **Risk:** Low | **Priority:** 🔴 Critical

### 2.1 Background

On June 22, 2024, a single IP (`37.143.63.171`) registered ~33 accounts and
created 16 SEO spam pages about sofas/furniture. Admin **Vysakh** mass-blocked
30 accounts + the IP within hours. Admin **Sreehari Sanjeev** deleted all 16
spam pages on June 29. Good incident response.

However, **3 accounts slipped through** — they registered *after* the mass-block
and remain unblocked sleeper accounts:

### 2.2 Accounts to Block

| User             | User ID | Registered (UTC)       | Edits | Status         |
|------------------|---------|------------------------|-------|----------------|
| DeniseHaber5     | 149     | 2024-06-22 13:24:57    | 0     | 🔴 NOT BLOCKED |
| FlorrieColleano  | 150     | 2024-06-22 13:38:04    | 0     | 🔴 NOT BLOCKED |
| Rae57A1886121    | 151     | 2024-06-22 13:40:30    | 0     | 🔴 NOT BLOCKED |

**Action:** Block all 3 accounts (indefinite, prevent account creation).

### 2.3 Pages to Delete

**None remaining.** All 16 spam pages were already deleted:

<details>
<summary>Deleted spam pages (for reference)</summary>

All were SEO link-spam about sofas/couches, created by the bot accounts:

- "The Most Effective Reasons For People To Succeed At The Leather Sofas For Sale Industry"
- "15 Sectional Couches For Sale Benefits That Everyone Should Know"
- "Leather Modular Sofa: 11 Thing You re Leaving Out"
- "7 Simple Tricks To Rolling With Your U Shaped Sectional"
- "5 Tools That Everyone Working Who Works In The U Shaped Sectional With Chaise Industry Should Be Using"
- "Where Can You Find The Top Convertible Sectional Sofa Information"
- "9 Things Your Parents Teach You About Futon Sleeper Sofa"
- "Why You Should Concentrate On Improving Small Leather Couch"
- "The Most Powerful Sources Of Inspiration Of Outdoor Sectional Sofa"
- "The Most Pervasive Issues In Sleeper Sectionals"
- "The 3 Largest Disasters In U Shaped Settee…"
- "Do Not Buy Into These Trends Concerning L Shaped Couch"
- "8 Tips To Increase Your Leather Sectional Sleeper Sofa Game"
- "Guide To Huge U Shaped Couch…"
- "How To Determine If You re In The Right Place To Go After Sectional L Shaped Sectional"
- "The Evolution Of L Couches For Sale"

</details>

### 2.4 Preventive Measures

- [ ] Consider enabling **CAPTCHA on account creation** if not already active — the bot registered 33 accounts in ~9 hours.
- [ ] Review AbuseFilter rules to auto-flag mass registrations from a single IP range.
- [ ] IP `37.143.63.171` is already permanently blocked ✅.

---

## 3. Phase 2 — Duplicate Resolution

**Effort:** ~2 hours | **Risk:** Medium (need to merge content carefully) | **Priority:** 🔴 High

### 3.1 Immediate Fixes — Wrong Redirects (actively misleading users)

These are **broken right now** and should be fixed first:

| Page                      | Current Target              | Correct Target           | Problem                      |
|---------------------------|-----------------------------|--------------------------|------------------------------|
| `Discrete mathematics-1`  | `Discrete Structures-II`    | `Discrete Structures-I`  | Points to wrong course       |
| `Class Representatives`   | `Branch Representatives`    | `Class Representative`   | Different roles entirely     |
| `Broasted restaurant`     | → `Broasted Restaurant` → `BroastRestaurant` | `Broasted Restaurant` | Double redirect (MW won't follow) |

### 3.2 Simple Redirects (stub/empty page → good page)

These pages are stubs or empty — replace content with `#REDIRECT [[Target]]`:

| Page to Redirect             | Target (canonical)                                  | Reason                       |
|------------------------------|-----------------------------------------------------|------------------------------|
| `FOSSMeet 2025`              | `FOSSMeet'25`                                       | Empty page                   |
| `FOSSMeet 2023`              | `FOSSMeet'23`                                       | Stub ("init" only)           |
| `GDSC Club`                  | `GDSC NITC`                                         | Stub → comprehensive page    |
| `Cloud computing lab`        | `Cloud Computing Lab`                               | One-line stub → detailed page|
| `COOPS`                      | `Cooperative Store(COOPS)`                           | One-line stub → full page    |
| `MATHEMATICS 1`              | `Mathematics I`                                     | Old curriculum → current     |
| `Centre for Materials Characterization (CMC) NITC` | `Centre for Materials Characterization` | Near-identical content       |
| `ECE block 1`                | `ECE Block 1`                                       | Case variant (merge antenna note first) |
| `ECE block 2`                | `ECE Block 2`                                       | Case variant                 |
| `DISTRETE1`                  | `Discrete Structures-I`                             | Typo variant with dup content|
| `Literary and Debate Club`   | `Literary and Debating Club`                        | Replace inline link with proper redirect |

### 3.3 Content Merges (both pages have unique content — combine before redirecting)

These require reading both pages and merging the best content into the canonical page:

| Canonical Page (keep)                                  | Page to Merge & Redirect                    | What to Merge                                    |
|--------------------------------------------------------|---------------------------------------------|--------------------------------------------------|
| `CCC`                                                  | `Central Computer Centre (CCC) NITC`        | Server specs, infrastructure details, hours       |
| `Engineering Unit`                                     | `Engineering Unit NITC`                     | Staff list, service links, QR codes               |
| `Guest House`                                          | `Guest House NITC`                          | Mapframe, booking details, terminal descriptions  |
| `Industrial and Planning Forum`                        | `Industrial And Planning Forum`             | Club logo image, external links                   |
| `Department of Computer Science and Engineering (CSED)`| `Department of computer science and engineering` | Research areas list, lab links                |
| `Internship`                                           | `Intership`                                 | B21 batch info (2 lines)                          |
| `Broasted Restaurant`                                  | `BroastRestaurant`                          | Reverse redirect direction; move content here     |

### 3.4 Already Resolved (no action needed) ✅

These duplicates have working redirects already in place:

- `FOSSMeet/24` → `FOSSMeet'24` ✅
- `Malayalam streetplay` → `Malayalam Streetplay` ✅
- `KAROONJIMALA` → `Karoonjimala` ✅
- `Class Comittees` → `Class Committees` ✅
- `DISCRETE1` → `Discrete Structures-I` ✅
- `Indoor badminton court` → `LH badminton court` ✅

### 3.5 Not Duplicates (confirmed different topics)

These looked similar but are actually distinct pages — no action needed:

- `A HOSTEL` vs `A hostel common room` — hostel vs specific room
- `GLUG NITC` vs `GLUG INFRA` vs `FOSSCell` — community vs infra project vs club
- `FOSS` vs `FLOSS Meet` vs `FOSSCell` — concept vs historical event name vs club
- `Computer Science and Engineering` (1134) vs `Department of CSE (CSED)` (655) — curriculum page vs department overview (cross-link them)
- `Electronics And Communication Engineering` (1129) vs `Department Of ECE` (482) — same pattern: curriculum vs department

---

## 4. Phase 3 — Category Overhaul

**Effort:** ~4-6 hours (257 pages need tagging) | **Risk:** Low | **Priority:** 🟡 High

### 4.1 The Problem

- **93.8%** of content pages (257 of 274) have **zero categories**.
- `Category:Places in NITC` exists but has **0 members** despite 100+ place pages.
- 14 of 39 categories should be deleted (date categories, single-page workshop tracks).
- FOSSMeet 2013 alone sits in 9 categories. Most FOSSMeet pages have 0.

### 4.2 Categories to Delete (14)

| Category                       | Members | Reason                                      |
|--------------------------------|---------|---------------------------------------------|
| `Places in NITC`               | 0       | Empty. Replace with new `Campus` tree.      |
| `Others`                       | 1       | Junk drawer anti-pattern.                   |
| `Design Web and Mobile`        | 1       | FOSSMeet 2013 workshop track, not a wiki category. |
| `Enterprise Security and Cloud`| 1       | Same.                                       |
| `Languages Tools and Platforms`| 1       | Same.                                       |
| `Mini DebConf`                 | 1       | Merge into new `Conferences`.               |
| `Special Event`                | 1       | Merge into `Events`.                        |
| `FOSSMeet 2005`                | 1       | Too specific. Use year subcats only if needed. |
| `2013`                         | 1       | Year-only category not useful.              |
| `10 August 2024`               | auto    | Date category, no editorial value.          |
| `11 August 2024`               | auto    | Same.                                       |
| `16 June 2024`                 | auto    | Same.                                       |
| `29 January 2024`              | auto    | Same.                                       |
| `2 July 2025`                  | auto    | Same.                                       |

### 4.3 Categories to Rename (4)

| Current Name           | New Name             | Reason                     |
|------------------------|----------------------|----------------------------|
| `Centres`              | `Research Centres`   | Clarifies meaning          |
| `Minutes`              | `SAC Minutes`        | Scopes to actual content   |
| `Festival Celebrations`| `Festivals`          | Shorter, more natural      |
| `Blogs FOSSMEET`       | `Blog Posts`         | Broaden beyond FOSSMeet    |

### 4.4 New Categories to Create (~15)

| New Category                 | Parent                   | Est. Pages |
|------------------------------|--------------------------|------------|
| `Campus`                     | root                     | parent     |
| `Hostels`                    | `Campus`                 | 15–20      |
| `Academic Buildings`         | `Campus`                 | 10–15      |
| `Grounds and Courts`         | `Campus`                 | 10–15      |
| `Amenities`                  | `Campus`                 | 10–15      |
| `Gates and Landmarks`        | `Campus`                 | 5–10       |
| `Nearby Places`              | `Campus`                 | 5–10       |
| `Departments`                | `Academics`              | 15–20      |
| `Courses`                    | `Academics`              | 30–40      |
| `Laboratories`               | `Academics`              | 40–50      |
| `Faculty`                    | `Academics` + `People`   | 20–25      |
| `Clubs and Organizations`    | `Student Life`           | 20–30      |
| `Sports Teams`               | `Student Life`           | 15–20      |
| `Student Government`         | `Student Life`           | 30–40      |
| `Food and Eateries`          | `Student Life`           | 10–15      |
| `People`                     | root                     | parent     |
| `FOSSMeet Speakers`          | `People`                 | 20–30      |
| `Workshops`                  | `Events`                 | 10–15      |
| `Ragam`                      | `Events`                 | 3–5        |
| `Conferences`                | `Events`                 | 2–5        |
| `Stubs`                      | `Wiki Maintenance`       | TBD        |

### 4.5 Full Proposed Category Tree

See [Appendix B](#appendix-b-proposed-category-tree).

### 4.6 Mass Tagging Execution Order

1. **Campus places** — highest page count, easiest to classify (~80–100 pages)
2. **FOSSMeet pages** — 2005–2026, all uncategorized (~15–20 pages)
3. **SAC minutes/agendas** — mechanical, ~30 pages
4. **Labs** — mechanical, ~40 pages
5. **Clubs and sports teams** — ~35 pages
6. **Faculty and speakers** — ~40 pages
7. **Courses** — ~30–40 pages
8. **Everything else** — food, policies, misc

---

## 5. Phase 4 — Template System

**Effort:** ~6-8 hours (create templates + retrofit key pages) | **Risk:** Medium | **Priority:** 🟡 High

### 5.1 Current State

> **UPDATE 2026-05-17:** `Template:Infobox FOSSMeet` is now live and deployed on `2026:FOSSMeet`.
> Navigation templates `{{FOSSMeet Tabs}}` and `{{FOSSMeet Navbox}}` also live.
> Year-based namespaces (1961–currentYear+2) configured in LocalSettings.php.
> See `wiki.fosscell.org/PROGRESS.md` for full details.

- ~~**Zero infobox templates exist** on the wiki.~~ → `Template:Infobox FOSSMeet` deployed ✅
- Every page is freeform wikitext with wildly inconsistent formatting.
- ~~Only one content template found: `{{Foss-meet-at-nitc}}`~~ → replaced by `{{FOSSMeet Navbox}}` ✅

### 5.2 Templates to Create (8, in priority order)

| # | Template                    | Est. Pages Affected | Effort  |
|---|-----------------------------|--------------------|---------|
| 1 | `{{Infobox SAC Meeting}}`   | 30–50+             | Medium  |
| 2 | `{{Infobox Club}}`          | 20–30              | Low     |
| 3 | `{{Infobox Course}}`        | 40–60+             | Medium  |
| 4 | `{{Infobox Person}}`        | 30–50              | Low     |
| 5 | `{{Infobox FOSSMeet}}`      | 15–20              | Low     |
| 6 | `{{Infobox Faculty}}`       | 20–30              | Medium  |
| 7 | `{{Infobox Hostel}}`        | 10–15              | Low     |
| 8 | `{{Infobox Campus Location}}`| 20–30             | Low     |

### 5.3 Template Specifications

Full field lists and example wikitext for each template are in [Appendix C](#appendix-c-template-specifications).

### 5.4 Standard Page Structures

Each template comes with a recommended section layout. Example for a **Club page**:

```
{{Infobox Club
| name           = FOSSCell
| logo           = FOSSCell_logo.png
| type           = Technical
| founded        = 2004
| faculty_advisor= Dr. Vinod Pathari
| flagship_event = FOSSMeet
| website        = https://fosscell.org
| github         = fosscell
| telegram       = fosscellnitc
}}

== About ==

== Events ==
=== FOSSMeet ===
=== FridayNightFOSS ===

== Teams / Structure ==

== How to Join ==

== Achievements ==

== Notable Members / Alumni ==

== History ==

== External Links ==

{{Foss-meet-at-nitc}}   <!-- revive the nav footer -->

[[Category:Clubs and Organizations]]
[[Category:Technical Clubs]]
```

### 5.5 Auto-Categorization

Each template should automatically add the page to the appropriate category:
- `{{Infobox Club}}` → `[[Category:Clubs and Organizations]]`
- `{{Infobox Faculty}}` → `[[Category:Faculty]]`
- `{{Infobox Hostel}}` → `[[Category:Hostels]]`
- `{{Infobox Course}}` → `[[Category:Courses]]`
- `{{Infobox FOSSMeet}}` → `[[Category:FOSSMeet]]` + `[[Category:Events]]`

### 5.6 Revive `{{Foss-meet-at-nitc}}`

The existing navigation footer template should be:
1. Updated to include all FOSSMeet editions (2005–2026)
2. Applied to every FOSSMeet page (currently only on 2005, 2006, 2007)

---

## 6. Phase 5 — Naming Conventions

**Effort:** ~1 hour to document, ongoing to enforce | **Priority:** 🟢 Medium

### 6.1 Page Title Standards

| Content Type    | Convention                                        | Example                              |
|-----------------|---------------------------------------------------|--------------------------------------|
| FOSSMeet events | `FOSSMeet'YY`                                     | `FOSSMeet'26`                        |
| SAC meetings    | `SAC Meeting YYYY-MM-DD (TYPE-NN)`                | `SAC Meeting 2022-05-15 (RM-01)`    |
| Departments     | `Department of X`                                 | `Department of Computer Science and Engineering` |
| Hostels         | `X Hostel`                                        | `A Hostel`, `G Hostel`               |
| Courses         | `Course Name (CODE)`                              | `Hardware Lab (CS2093D)`             |
| Labs            | `X Laboratory` or short name                      | `Cloud Computing Lab`                |
| Faculty         | `Dr. Firstname Lastname`                          | `Dr. Saleena N`                      |
| Clubs           | Full official name                                | `Literary and Debating Club`         |
| Campus places   | Title Case, no `NITC` suffix                      | `Guest House` not `Guest House NITC` |

### 6.2 Capitalization Rules

- **Title Case** for all page titles (not ALL CAPS, not lowercase)
- Exception: acronyms (`ECLC`, `ELHC`, `CCC`)
- Redirect from common variants (lowercase, ALL CAPS, abbreviations)

---

## 7. Phase 6 — Ongoing Governance

### 7.1 Editing Guidelines Page

Create a `Wiki:Editing Guidelines` page covering:
- [ ] Every new page MUST have at least one category
- [ ] Use the appropriate infobox template for the content type
- [ ] Follow the naming conventions above
- [ ] No orphan pages — every page must be linked from at least one other page
- [ ] Meeting minutes use the `{{Infobox SAC Meeting}}` template

### 7.2 Stub Policy

- Pages under 100 bytes should be tagged with `{{stub}}` (create this template)
- Target: no stubs older than 6 months without improvement

### 7.3 Review Cadence

- Monthly: check `Special:UncategorizedPages` — target: 0
- Monthly: check `Special:ShortPages` — expand or merge stubs
- Quarterly: review `Special:WantedPages` — create or delink red links
- After each FOSSMeet: ensure event page uses `{{Infobox FOSSMeet}}`

### 7.4 Anti-Spam

- [ ] Enable CAPTCHA on account creation
- [ ] Review AbuseFilter rules quarterly
- [ ] Block sleeper accounts from June 2024 wave (see Phase 1)

---

## Execution Timeline

| Phase | What                          | Est. Effort  | Dependencies |
|-------|-------------------------------|-------------|--------------|
| **1** | Spam cleanup (block 3 users)  | 30 min      | Admin access  |
| **2** | Fix wrong redirects (3 pages) | 15 min      | None          |
| **2** | Simple redirects (11 pages)   | 30 min      | None          |
| **2** | Content merges (7 pairs)      | 1.5 hours   | Read both pages first |
| **3** | Delete/rename old categories  | 30 min      | Admin access  |
| **3** | Create new category pages     | 1 hour      | Category tree agreed |
| **3** | Mass-tag 257 pages            | 4–5 hours   | Categories exist |
| **4** | Create 8 infobox templates    | 3–4 hours   | Template specs agreed |
| **4** | Retrofit key pages            | 3–4 hours   | Templates exist |
| **5** | Document naming conventions   | 1 hour      | None          |
| **6** | Create governance pages       | 1 hour      | None          |

**Total estimated effort: ~15–18 hours** spread across multiple sessions.

---

## Appendix A: Full Duplicate Map

### Already Resolved ✅

| Redirect Page              | Target                       |
|----------------------------|------------------------------|
| `FOSSMeet/24`              | `FOSSMeet'24`                |
| `Malayalam streetplay`      | `Malayalam Streetplay`        |
| `KAROONJIMALA`             | `Karoonjimala`               |
| `Class Comittees`          | `Class Committees`           |
| `DISCRETE1`               | `Discrete Structures-I`      |
| `Indoor badminton court`   | `LH badminton court`         |

### Wrong Redirects 🔴

| Page                     | Currently Points To       | Should Point To          |
|--------------------------|---------------------------|--------------------------|
| `Discrete mathematics-1` | `Discrete Structures-II`  | `Discrete Structures-I`  |
| `Class Representatives`  | `Branch Representatives`  | `Class Representative`   |

### Double Redirect 🟡

| Chain                                                         | Fix                                |
|---------------------------------------------------------------|------------------------------------|
| `Broasted restaurant` → `Broasted Restaurant` → `BroastRestaurant` | Reverse: make `Broasted Restaurant` canonical |

### New Redirects Needed

| From                                                    | To (canonical)                                         |
|---------------------------------------------------------|--------------------------------------------------------|
| `FOSSMeet 2025`                                         | `FOSSMeet'25`                                          |
| `FOSSMeet 2023`                                         | `FOSSMeet'23`                                          |
| `GDSC Club`                                             | `GDSC NITC`                                            |
| `Cloud computing lab`                                   | `Cloud Computing Lab`                                  |
| `COOPS`                                                 | `Cooperative Store(COOPS)`                             |
| `MATHEMATICS 1`                                         | `Mathematics I`                                        |
| `Centre for Materials Characterization (CMC) NITC`      | `Centre for Materials Characterization`                |
| `ECE block 1`                                           | `ECE Block 1`                                          |
| `ECE block 2`                                           | `ECE Block 2`                                          |
| `DISTRETE1`                                             | `Discrete Structures-I`                                |
| `Literary and Debate Club`                              | `Literary and Debating Club`                           |

### Content Merges Required

| Keep (canonical)                                         | Merge From                              | Content to Transfer                       |
|----------------------------------------------------------|-----------------------------------------|-------------------------------------------|
| `CCC`                                                    | `Central Computer Centre (CCC) NITC`    | Server specs, infra details, opening hours|
| `Engineering Unit`                                       | `Engineering Unit NITC`                 | Staff list, service links, QR codes       |
| `Guest House`                                            | `Guest House NITC`                      | Mapframe, booking, terminal descriptions  |
| `Industrial and Planning Forum`                          | `Industrial And Planning Forum`         | Club logo, external links                 |
| `Department of Computer Science and Engineering (CSED)`  | `Department of computer science and engineering` | Research areas, lab links          |
| `Internship`                                             | `Intership`                             | B21 batch info                            |
| `Broasted Restaurant`                                    | `BroastRestaurant`                      | Move all content here, reverse redirect   |

---

## Appendix B: Proposed Category Tree

```
Category:NITC Wiki                              ← root
├── Category:Campus
│   ├── Category:Hostels
│   ├── Category:Academic Buildings
│   ├── Category:Grounds and Courts
│   ├── Category:Amenities
│   ├── Category:Gates and Landmarks
│   └── Category:Nearby Places
│
├── Category:Academics
│   ├── Category:Departments
│   ├── Category:Courses
│   ├── Category:Laboratories
│   ├── Category:Faculty
│   ├── Category:Research Centres
│   └── Category:Academic Policies
│
├── Category:Student Life
│   ├── Category:Clubs and Organizations
│   │   ├── Category:Technical Clubs
│   │   └── Category:Cultural Clubs
│   ├── Category:Sports Teams
│   ├── Category:Student Government
│   │   ├── Category:SAC Minutes
│   │   └── Category:SAC Agendas
│   └── Category:Food and Eateries
│
├── Category:Events
│   ├── Category:FOSSMeet
│   ├── Category:Tathva
│   ├── Category:Ragam
│   ├── Category:Workshops
│   ├── Category:Hackathons
│   ├── Category:Festivals
│   └── Category:Conferences
│
├── Category:People
│   ├── Category:Faculty                        (shared with Academics)
│   ├── Category:FOSSMeet Speakers
│   ├── Category:Alumni
│   └── Category:Students
│
├── Category:Administration
│   ├── Category:Institute Administration
│   └── Category:Policies and Regulations
│
├── Category:Projects
│   ├── Category:Software Projects
│   └── Category:Hardware Projects
│
├── Category:Blog Posts
│
└── Category:Wiki Maintenance
    ├── Category:Pages with broken file links   (auto)
    ├── Category:Pages with script errors       (auto)
    └── Category:Stubs
```

---

## Appendix C: Template Specifications

### C.1 `{{Infobox SAC Meeting}}`

**Purpose:** Standardize the ~30–50 meeting minutes/agenda pages.

**Fields:**

| Field            | Required | Description                                        |
|------------------|----------|----------------------------------------------------|
| `type`           | ✅       | GBM / RM / EM (General Body / Regular / Emergency) |
| `number`         | No       | Meeting number in the series                       |
| `reference`      | No       | Formal reference (e.g. NITC/SAC2021/SPO/05)        |
| `date`           | ✅       | ISO 8601 date                                      |
| `time_start`     | ✅       | 24h format                                         |
| `time_end`       | No       |                                                    |
| `venue`          | ✅       |                                                    |
| `academic_year`  | ✅       | e.g. 2021-22                                       |
| `chair`          | No       | Who presided                                       |
| `speaker`        | No       | SAC Speaker name                                   |
| `quorum_met`     | ✅       | yes / no                                           |
| `attendees`      | No       | Count                                              |
| `agenda_page`    | No       | Link to separate agenda page                       |
| `previous`       | No       | Link to previous meeting                           |
| `next`           | No       | Link to next meeting                               |

**Standard sections:** Announcements → Reports → Transactions → Decisions & Action Items → Attendees

**Auto-categories:** `[[Category:SAC Minutes]]` + `[[Category:Student Government]]`

---

### C.2 `{{Infobox Club}}`

**Purpose:** Standardize the ~20–30 club/organization pages.

**Fields:**

| Field              | Required | Description                                  |
|--------------------|----------|----------------------------------------------|
| `name`             | ✅       |                                              |
| `logo`             | No       | Filename                                     |
| `type`             | ✅       | Technical / Cultural / Non-Technical / Professional |
| `founded`          | No       | Year                                         |
| `parent_org`       | No       | e.g. "Literary and Debating Club"            |
| `faculty_advisor`  | No       |                                              |
| `affiliated_with`  | No       | e.g. "IEEE" for IEEE student branch          |
| `flagship_event`   | No       | e.g. "Samasya"                               |
| `website`          | No       |                                              |
| `instagram`        | No       |                                              |
| `telegram`         | No       |                                              |
| `github`           | No       |                                              |
| `email`            | No       |                                              |

**Standard sections:** About → Events → Teams/Structure → How to Join → Achievements → Notable Members → History → External Links

**Auto-categories:** `[[Category:Clubs and Organizations]]` + type-specific subcat

---

### C.3 `{{Infobox Course}}`

**Purpose:** Standardize the ~40–60 course/lab pages.

**Fields:**

| Field            | Required | Description                               |
|------------------|----------|-------------------------------------------|
| `name`           | ✅       | Full course name                          |
| `code`           | ✅       | e.g. CS2093D                              |
| `department`     | ✅       |                                           |
| `type`           | ✅       | Theory / Lab / Theory+Lab / Project       |
| `credits`        | ✅       |                                           |
| `semester`       | No       | e.g. "S3 (3rd semester)"                  |
| `offered_to`     | No       | e.g. "B.Tech CSE"                         |
| `prerequisites`  | No       |                                           |
| `instructor`     | No       | Current instructor(s)                     |
| `textbook`       | No       | Primary textbook                          |
| `website`        | No       | Course website URL                        |

**Standard sections:** Overview → Topics → Grading → References → Resources → Student Tips

**Auto-categories:** `[[Category:Courses]]` + department subcat

---

### C.4 `{{Infobox Person}}`

**Purpose:** Standardize the ~30–50 speaker/notable person pages.

**Fields:**

| Field               | Required | Description                            |
|---------------------|----------|----------------------------------------|
| `name`              | ✅       |                                        |
| `image`             | No       |                                        |
| `affiliation`       | No       | Current org/company                    |
| `role`              | No       | e.g. "Debian Developer"               |
| `known_for`         | No       | Brief claim-to-fame                    |
| `website`           | No       |                                        |
| `github`            | No       |                                        |
| `fossmeet_editions` | No       | e.g. "2006, 2024"                      |
| `nitc_alumnus`      | No       | yes / no                               |
| `batch`             | No       | NITC batch if alumnus                  |

**Standard sections:** Biography → Contributions → Talks at FOSSMeet → External Links

**Auto-categories:** `[[Category:People]]` + `[[Category:FOSSMeet Speakers]]` (if applicable)

---

### C.5 `{{Infobox FOSSMeet}}`

**Purpose:** Standardize the ~15–20 FOSSMeet event pages.

**Fields:**

| Field            | Required | Description                               |
|------------------|----------|-------------------------------------------|
| `edition`        | ✅       | e.g. 20                                  |
| `year`           | ✅       | e.g. 2026                                |
| `image`          | No       | Poster or group photo                     |
| `dates`          | ✅       | e.g. "10–12 April 2026"                  |
| `venue`          | ✅       |                                           |
| `website`        | No       |                                           |
| `theme`          | No       |                                           |
| `speakers`       | No       | Count                                     |
| `attendees`      | No       | Count                                     |
| `workshops`      | No       | Count                                     |
| `talks`          | No       | Count                                     |
| `faculty_coord`  | No       |                                           |
| `previous`       | No       | Link to previous edition                  |
| `next`           | No       | Link to next edition                      |

**Standard sections:** About → Schedule (Day 1/2/3) → Speakers (wikitable) → Sub Committees → Gallery → Blog Posts & Media → See Also

**Auto-categories:** `[[Category:FOSSMeet]]` + `[[Category:Events]]`

---

### C.6 `{{Infobox Faculty}}`

**Purpose:** Standardize the ~20–30 faculty profile pages.

**Fields:**

| Field             | Required | Description                              |
|-------------------|----------|------------------------------------------|
| `name`            | ✅       |                                          |
| `image`           | No       |                                          |
| `designation`     | ✅       | Professor / Associate / Assistant        |
| `department`      | ✅       |                                          |
| `qualification`   | ✅       | Highest degree                           |
| `specialization`  | No       | Research area                            |
| `email`           | No       |                                          |
| `phone`           | No       |                                          |
| `office`          | No       | Room number                              |
| `website`         | No       |                                          |
| `scholar`         | No       | Google Scholar URL                       |
| `scopus`          | No       |                                          |
| `orcid`           | No       |                                          |
| `joined`          | No       | Year joined NITC                         |

**Standard sections:** Biography → Educational Qualifications → Research Interests → Publications → Courses Handled → PhD Students → Administrative Responsibilities

**Auto-categories:** `[[Category:Faculty]]` + `[[Category:CSED Faculty]]` (department-specific)

---

### C.7 `{{Infobox Hostel}}`

**Purpose:** Standardize the ~10–15 hostel pages.

**Fields:**

| Field             | Required | Description                              |
|-------------------|----------|------------------------------------------|
| `name`            | ✅       |                                          |
| `image`           | No       |                                          |
| `campus`          | ✅       | Main Campus / East Campus                |
| `gender`          | ✅       | Boys / Girls / Co-ed                     |
| `residents`       | ✅       | e.g. "1st year B.Tech"                   |
| `capacity`        | No       | Number of students                       |
| `room_types`      | No       | e.g. "Single, Double (4-person)"         |
| `floors`          | No       |                                          |
| `mess`            | No       | e.g. "Non-veg (A Mess)"                  |
| `warden`          | No       |                                          |
| `facilities`      | No       | e.g. "Coop store, Laundry"              |
| `adjacent_to`     | No       | Nearby landmarks                         |
| `coordinates`     | No       | lat,lon                                  |

**Standard sections:** About → Facilities → Mess → Administration → Location → History

**Auto-categories:** `[[Category:Hostels]]` + `[[Category:Campus]]`

---

### C.8 `{{Infobox Campus Location}}`

**Purpose:** Standardize the ~20–30 campus place pages.

**Fields:**

| Field             | Required | Description                              |
|-------------------|----------|------------------------------------------|
| `name`            | ✅       |                                          |
| `image`           | No       |                                          |
| `type`            | ✅       | Building / Ground / Area / Facility      |
| `campus`          | ✅       | Main Campus / East Campus                |
| `also_known_as`   | No       | Abbreviation or nickname                 |
| `houses`          | No       | e.g. "CSED, CNC"                         |
| `built`           | No       | Year                                     |
| `coordinates`     | No       |                                          |

**Standard sections:** About → Facilities → Location → History → Gallery

**Auto-categories:** `[[Category:Campus]]` + type-specific subcat

---

*End of WikiRoadmap.md*
