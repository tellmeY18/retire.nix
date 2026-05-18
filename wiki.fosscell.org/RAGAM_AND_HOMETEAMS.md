# Ragam & Home Teams — Namespace & Structure Plan

## Context

Ragam is NITC's annual inter-college cultural festival (South India's largest). It dates back to
1987 and is deeply connected to **Home Teams** — the cultural, technical, and sports teams that
represent NITC at inter-college competitions and also perform at Ragam.

The question: **How should Home Teams relate to Ragam in the namespace hierarchy?**

---

## The Relationship

```
Ragam (festival) ─── Annual event, happens once a year
    │
    ├── Competitions (inter-college)
    ├── Pro-shows (concerts)
    └── Home Team performances

Home Teams ─── Permanent institutions (exist year-round)
    │
    ├── Cultural: Mime, Drama, Street Play, Spoof, Fashion, Dance, Music
    ├── Technical: Aerounwired, Unwired, CP Hub, Quiz
    └── Sports: Football, Basketball, Cricket, Athletics...
```

**Key insight:** Home Teams are NOT children of Ragam. They exist independently.
But they DO have **yearly lifecycle data** — members change, achievements happen per year,
participations are tracked per academic year.

---

## Decision: Hybrid Approach (Option A+)

Home Teams live in the **main namespace** as permanent entities, BUT they get **yearly
report pages in the year namespace** to track time-specific data.

### Why pure Option A (main namespace only) is insufficient

The main page for a home team would grow unmanageably large if every year's members,
achievements, participations, and documentation are dumped into sections. After 10 years
of data, the NITC Mime Team page would be 50+ screens of member lists and competition
results.

### The hybrid solution

```
Main namespace (permanent identity):
    NITC Mime Team               ← {{Infobox Home Team}}, overview, traditions, "See also" links
    The Act                      ← Same
    Team Unwired                 ← Same + technical docs section

Year namespace (yearly reports):
    2026:NITC Mime Team          ← That year's members, achievements, participations
    2026:NITC Mime Team/Coverage ← YouTube links, news articles, competition videos
    2025:NITC Mime Team          ← Previous year
    ...

    2026:Ragam                   ← The festival edition
    2026:Ragam/Schedule
    2026:Ragam/Performers        ← Links to all home team year-pages that performed
    2026:Ragam/Competitions
    2026:Ragam/Team
    2026:Ragam/Gallery
    2026:Ragam/Coverage

    2026:Team Unwired            ← That year's projects, members, competition results
    2026:Team Unwired/Docs       ← Technical documentation specific to that year's robot/project
```

### What lives WHERE

| Data | Location | Why |
|---|---|---|
| Team identity (name, founding, discipline, traditions) | `NITC Mime Team` (main) | Permanent, doesn't change |
| Team logo, description, training process | `NITC Mime Team` (main) | Permanent |
| This year's members | `2026:NITC Mime Team` | Changes every year |
| This year's achievements | `2026:NITC Mime Team` | Year-specific |
| This year's competition participations | `2026:NITC Mime Team` | Year-specific |
| YouTube performance videos | `2026:NITC Mime Team/Coverage` | Year-specific media |
| News articles about the team this year | `2026:NITC Mime Team/Coverage` | Year-specific |
| Technical docs (Unwired robot design) | `2026:Team Unwired/Docs` | Year-specific (new robot each year) |
| Which teams performed at Ragam 2026 | `2026:Ragam/Performers` | Event-edition-specific |
| Pro-show artists for Ragam 2026 | `2026:Ragam/Performers` | Event-edition-specific |

---

## Full Page Structure

### Main page: `NITC Mime Team` (permanent)

```wikitext
{{Infobox Home Team
| name         = NITC Mime Team
| image        = Mime Ragam 23.png
| type         = Cultural
| discipline   = Classical French Mime
| founded      = 2009
| batch_size   = 9–11 (including pianist)
| induction_year = 1st year only
| parent_fest  = [[Ragam]]
| instagram    = https://instagram.com/nitcmime
}}

== About ==
Brief description: classical French mime, gestures, facial expressions, crisp movements.
Training by seniors in 2nd, 3rd, 4th years. Inductions from large pool of first-year aspirants.

== Traditions ==
(Brotherhood, training culture, rituals)

== Yearly Reports ==
* [[2026:NITC Mime Team|2025–26]] — current year
* [[2025:NITC Mime Team|2024–25]]
* [[2024:NITC Mime Team|2023–24]]
* ...

== All-Time Notable Achievements ==
(Top 5 biggest wins across all years — curated, not exhaustive)

== See also ==
* [[Home Teams]]
* [[Ragam]]
```

### Year page: `2026:NITC Mime Team`

```wikitext
{{Home Team Year Tabs|base=2026:NITC Mime Team}}
{{Infobox Home Team Year
| team       = NITC Mime Team
| year       = 2025–26
| batch      = B23
| captain    = (name)
| members    = 10
| achievements = 3 prizes
| image      = (group photo)
}}

== Members ==
{| class="wikitable"
! Name !! Role !! Batch
|-
| ... || Captain || B23
|-
| ... || Pianist || B23
|-
| ... || Member || B23
|}

== Achievements ==
* 🥇 '''Mood Indigo, IIT Bombay''' — 1st place (January 2026)
* 🥇 '''Dhanak, IIST Trivandrum''' — 1st place (November 2025)
* 🥈 '''Incident, NIT Surathkal''' — 2nd place (March 2026)

== Participations ==
{| class="wikitable"
! Event !! College !! Date !! Result
|-
| Mood Indigo || IIT Bombay || Jan 2026 || 🥇 1st
|-
| Ragam'26 || NIT Calicut || Mar 2026 || Performed (home)
|-
| Incident || NIT Surathkal || Mar 2026 || 🥈 2nd
|}

== See also ==
* [[NITC Mime Team]] — main page
* [[2026:NITC Mime Team/Coverage]] — videos and press

{{Home Team Navbox|team=NITC Mime Team}}
```

### Year subpage: `2026:NITC Mime Team/Coverage`

```wikitext
{{Home Team Year Tabs|base=2026:NITC Mime Team}}
= NITC Mime Team 2025–26 — Coverage =

== Performance Videos ==
* [https://youtube.com/... Mood Indigo 2026 — winning performance]
* [https://youtube.com/... Ragam'26 performance]

== News Articles ==
* [https://nitc.ac.in/news/... NIT Calicut official announcement]
* [https://thehindu.com/... The Hindu coverage]

== Social Media ==
* [https://instagram.com/p/... Instagram reel — 50K views]
```

### Technical team example: `2026:Team Unwired`

```wikitext
{{Home Team Year Tabs|base=2026:Team Unwired}}
{{Infobox Home Team Year
| team       = Team Unwired
| year       = 2025–26
| captain    = (name)
| members    = 15
| project    = (Robot name/project name)
}}

== Members ==
(table)

== Project: (Robot Name) ==
Brief description of this year's build.

== Competitions ==
(participation table)

== See also ==
* [[Team Unwired]] — main page
* [[2026:Team Unwired/Docs]] — technical documentation
```

### Technical docs: `2026:Team Unwired/Docs`

```wikitext
{{Home Team Year Tabs|base=2026:Team Unwired}}
= Team Unwired 2025–26 — Technical Documentation =

== Robot Specifications ==
(specs table)

== Design ==
(CAD images, architecture description)

== Software ==
(firmware details, control systems, code repos)

== Lessons Learned ==
(what worked, what didn't — for next year's team)
```

---

## Templates Needed

### {{Infobox Home Team}} — main page infobox
Fields: name, image, logo, type, discipline, founded, founder, batch_size,
induction_year, training, parent_fest, instagram, website, achievements_count

### {{Infobox Home Team Year}} — year-page infobox
Fields: team, year, batch, captain, members, achievements, project, image

### {{Home Team Year Tabs}} — subpage navigation for year pages
Links: Main · Coverage · (Docs — only for technical teams)
Auto-detects from BASEPAGENAME.

### {{Home Team Navbox}} — bottom nav linking all year pages for a team
Shows: 2020 · 2021 · 2022 · 2023 · 2024 · 2025 · 2026
Parameter: `team=NITC Mime Team`

### {{Infobox Ragam}} — Ragam edition infobox
(Same as before — pro_show_artists, competitions_count, footfall, convenor, etc.)

### {{Ragam Tabs}} and {{Ragam Navbox}}
(Same as FOSSMeet pattern)

---

## Ragam Edition Subpages (unchanged from before)

- `YYYY:Ragam` — Main page (infobox, highlights)
- `YYYY:Ragam/Schedule` — Day-by-day program
- `YYYY:Ragam/Performers` — Home team performances + pro-shows (links to `YYYY:TeamName`)
- `YYYY:Ragam/Competitions` — Inter-college competition results
- `YYYY:Ragam/Team` — Organising committee
- `YYYY:Ragam/Gallery` — Photos
- `YYYY:Ragam/Coverage` — Press, social media, YouTube

---

## How the Cross-Links Work

```
                    ┌─────────────────┐
                    │  NITC Mime Team  │ (main namespace)
                    │  permanent page  │
                    └────────┬────────┘
                             │ "Yearly Reports" section links down
                ┌────────────┼────────────┐
                ▼            ▼            ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │2024:NITC Mime │ │2025:NITC Mime │ │2026:NITC Mime │
    │    Team       │ │    Team       │ │    Team       │
    └───────┬───────┘ └───────┬───────┘ └───────┬───────┘
            │                 │                 │
            ▼                 ▼                 ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │2024:NITC Mime │ │2025:NITC Mime │ │2026:NITC Mime │
    │Team/Coverage  │ │Team/Coverage  │ │Team/Coverage  │
    └───────────────┘ └───────────────┘ └───────────────┘

    Meanwhile, the Ragam edition page cross-links:

    ┌─────────────────────┐
    │    2026:Ragam        │
    │    /Performers       │───── links to ──── 2026:NITC Mime Team
    │                      │───── links to ──── 2026:The Act
    │                      │───── links to ──── 2026:NDC Voice
    └─────────────────────┘
```

---

## Tathva (same pattern)

```
Main namespace:           Year namespace:
  Team Unwired              2026:Tathva
  Aerounwired               2026:Tathva/Schedule
  CP Hub                    2026:Tathva/Competitions
  Enquire Quiz Club         2026:Tathva/Team
                            2026:Team Unwired
                            2026:Team Unwired/Docs
                            2026:Aerounwired
```

---

## Execution Order

1. [ ] Create `{{Infobox Home Team}}` template
2. [ ] Create `{{Infobox Home Team Year}}` template
3. [ ] Create `{{Home Team Year Tabs}}` template
4. [ ] Create `{{Home Team Navbox}}` template
5. [ ] Create `{{Infobox Ragam}}` / `{{Ragam Tabs}}` / `{{Ragam Navbox}}`
6. [ ] Restructure `NITC Mime Team` main page with new template
7. [ ] Create `2024:NITC Mime Team` and `2025:NITC Mime Team` from existing data
8. [ ] Create `2025:Ragam` as first structured Ragam edition (most recent with data)
9. [ ] Create stub year-pages for other home teams
10. [ ] Backfill Ragam editions where data exists (pro-show table → individual year pages)

---

## Validated Against Real Data

**NITC Mime Team:**
- B22 batch won at IIT Bombay (Mood Indigo 2024) AND MITS Kochi (Shreshta '23) — year-specific
- B23 batch won at IIST Trivandrum (Dhanak '24) — year-specific
- Members change every year (B19, B20, B21, B22, B23 sections already exist on wiki)
- ✅ Year pages (`2024:NITC Mime Team`) capture this perfectly

**Team Unwired:**
- Builds a NEW robot every year for Robocon/competitions
- Technical docs are year-specific (robot design, firmware, lessons)
- ✅ `2026:Team Unwired/Docs` is exactly right for this

**The Act (Drama):**
- Writes new original scripts each year
- Members rotate per batch
- Won at Ragam 2019, Ragam 2022, SRM — all year-specific
- ✅ Year pages capture this

**Ragam pro-shows:**
- Sonu Nigam 2017, Pritam 2016, Jubin Nautiyal 2023 — year-specific
- ✅ `YYYY:Ragam/Performers` is correct

**Cross-links verified:**
- `2026:Ragam/Performers` links to `2026:NITC Mime Team` (who performed that year)
- `2026:NITC Mime Team` links back to `2026:Ragam` (where they performed)
- `NITC Mime Team` (main) links to all year pages as a "Yearly Reports" section
- ✅ Full bidirectional linking works

---

## Open Questions

- [ ] What are the exact dates for recent Ragam editions? (2023, 2024, 2025, 2026)
- [ ] Which home teams performed at each Ragam? (Need cross-reference data)
- [ ] Should sports teams get year pages too? (Likely yes — season results, squad lists)
- [ ] Academic year vs calendar year: Mime Team "B22" spans 2022–2026 (4 years).
      Use the *active competition year* for namespace (when they competed), not batch start year.
      So B22 competing in 2024 → `2024:NITC Mime Team`.
