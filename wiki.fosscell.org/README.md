# wiki.fosscell.org

Context and tracking for the FOSSCell NITC wiki — https://wiki.fosscell.org

## Infrastructure

- **MediaWiki 1.45** on k8s (`k8s/clusters/glug-infra/mediawiki/`)
- **Extensions:** Cargo, CirrusSearch, InputBox, AJAXPoll, EmbedVideo, VoteNY, BlogPage, RSS, SocialProfile, CategoryTree, TemplateStyles, HitCounters, ContributionScores, SemanticMediaWiki
- **Search:** CirrusSearch + OpenSearch
- **Storage:** RustFS S3 for uploads, Redis for caching
- **Year namespaces:** 1961–currentYear+2 (auto-extending)

## Hard Rules

1. **AI does NOT write content.** AI structures, formats, templates. Humans write.
2. **No fabricated data.** Migrate existing; leave unknowns as `{{stub}}`.
3. **Templates define structure, not content.** Fields left blank when data isn't available.

## Templates — Current State

### ✅ Live & Working

| Template | Cargo Table | Purpose |
|----------|-------------|---------|
| `{{Event}}` | `Events` | "This Day in History" + structured queries |
| `{{This day in history}}` | — | Main page widget |
| `{{Upcoming events}}` | — | Main page widget |
| `{{Book Club Meeting}}` | `BookClubMeetings` | Monthly reading circles |
| `{{Magazine Submission}}` | `MagazineSubmissions` | Tag pages as magazine entries |
| `{{FOSSCell Activity}}` | `FOSSCellActivities` | Members log contributions |
| `{{FOSSCell Event}}` | `FOSSCellEvents` | Define FOSSCell events |
| `{{Task}}` | `WikiTasks` | Wiki task tracking (kanban) |
| `{{Community}}` | `Communities` | Organic interest groups |
| `{{User Profile}}` | `UserProfiles` | Rich profile card |
| `{{Infobox FOSSMeet}}` | — | 40+ field event infobox |
| `{{Infobox Event}}` | — | Generic recurring event infobox |
| `{{Infobox Person}}` | — | People, speakers, alumni |
| `{{Infobox Faculty}}` | — | Faculty members |
| `{{Infobox Hostel}}` | — | Hostel pages |
| `{{Infobox Campus Location}}` | — | Campus places |
| `{{Infobox Course}}` | — | Course pages |
| `{{Infobox Club}}` | — | Formal clubs |
| `{{Infobox SAC Meeting}}` | — | SAC minutes |
| `{{Infobox Home Team}}` | — | Ragam/Tathva home teams |
| `{{Infobox Home Team Year}}` | — | Yearly edition |
| `{{Campaign}}` | — | Promotional banners |
| `{{Nav Tiles}}` | — | Icon-tile grid navigation |
| `{{FOSSMeet Tabs}}` | — | Subpage navigation |
| `{{FOSSMeet Navbox}}` | — | All-editions bottom nav |

### ⚠️ Needs Attention

| Template | Issue |
|----------|-------|
| `{{Infobox}}` (base) | Lua error — Scribunto module broken |
| `{{Infobox sport overview}}` | Template loop detected |
| `{{Whos Online}}` | MW 1.45 compat issue |

## TODO — Remaining Work

### Content Structure (high priority)

- [ ] Mass-categorize ~257 uncategorized pages
- [ ] Create Ragam year-namespace pages (`2024:Ragam`, `2025:Ragam`, etc.)
- [ ] Create Tathva year-namespace pages (`2024:Tathva`, `2025:Tathva`, etc.)
- [ ] Backfill FOSSMeet historical editions with infobox data (2005–2024)
- [ ] Apply `{{Infobox Hostel}}` to 15+ hostel pages
- [ ] Apply `{{Infobox Campus Location}}` to 80+ campus place pages
- [ ] Apply `{{Infobox Course}}` to 40+ course pages
- [ ] Apply `{{Infobox Person}}` to speaker/alumni pages

### Cleanup (medium priority)

- [ ] Block 3 sleeper spam accounts
- [ ] Fix 3 wrong redirects
- [ ] Merge 7 duplicate-content page pairs
- [ ] Delete 14 junk categories
- [ ] Rename 4 categories
- [ ] Create ~15 remaining categories from proposed tree

### Templates & Systems (to build)

- [ ] `{{Infobox Ragam}}` — Ragam-specific fields (theme, proshows, footfall)
- [ ] `{{Infobox Tathva}}` — Tathva-specific fields (tech events, workshops)
- [ ] `{{Ragam Navbox}}` — all-editions navigation (like FOSSMeet Navbox)
- [ ] `{{Tathva Navbox}}` — same for Tathva
- [ ] `{{Infobox Department}}` — for 15 department pages
- [ ] `{{Alumni Card}}` — compact card for alumni lists (batch, company, role)
- [ ] `{{stub}}` — standardized stub notice with categorization
- [ ] Fix base `{{Infobox}}` Lua module (Scribunto error)

### Governance & Docs

- [ ] Create formal naming conventions page
- [ ] Create stub policy page
- [ ] Document review cadence
- [ ] Create an "Adopt a Page" program for uncategorized content

## Conventions

### Page Naming
- Events: `YYYY:EventName` (e.g. `2026:FOSSMeet`, `2026:Ragam`)
- Subpages: `YYYY:EventName/Schedule`, `/Team`, `/Gallery`
- People: `Firstname Lastname` (main namespace)
- Clubs: `ClubName` (main namespace)

### Categories
- `[[Category:Events]]` — all events
- `[[Category:FOSSMeet YYYY]]` — per-edition
- `[[Category:Hostels]]`, `[[Category:Departments]]`, `[[Category:Courses]]`

## Architecture Decisions

| ADR | Decision |
|-----|----------|
| ADR-1 | Year namespaces over flat page names |
| ADR-2 | HTML `<tr>` in templates (wikitext `\|-` unreliable in parser functions) |
| ADR-3 | Dedicated job runner sidecar |
| ADR-4 | `/Roadmap` subpage for every event edition |
| ADR-5 | User namespace for member contributions (magazine, activities) |
| ADR-6 | Events defined once, contributions attached via Cargo |
| ADR-7 | `{{Community}}` for organic groups, `{{Infobox Club}}` for formal clubs |
