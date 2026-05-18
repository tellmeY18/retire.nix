# wiki.fosscell.org

Context and tracking for the FOSSCell NITC wiki (https://wiki.fosscell.org).

## Files

| File | Purpose |
|---|---|
| `ROADMAP.md` | Master cleanup & structuring plan (phases 1–6) |
| `PROGRESS.md` | Chronological log of all changes made + architecture decisions |

## Wiki Infrastructure

- **MediaWiki 1.44** on k8s (`k8s/clusters/glug-infra/mediawiki/`)
- **Year namespaces:** 1961–currentYear+2 (auto-extending)
- **Job runner:** sidecar container, drains queue continuously
- **Search:** CirrusSearch + OpenSearch
- **Storage:** RustFS S3 for uploads, Redis for caches

## Hard Rules

1. **AI does NOT write content.** AI is used ONLY for structuring, formatting, templates, and
   migration scaffolding. All actual wiki content (descriptions, history, member lists, achievement
   details, coverage links) MUST be written by humans. Stubs are placed; humans fill them.
2. **No fabricated data.** If information doesn't exist on the wiki already, don't invent it.
   Migrate existing data into new structures. Leave everything else as `{{stub}}`.
3. **Templates define structure, not content.** Infobox fields are left blank or marked TBD
   when data isn't available. Never populate a field with guessed or AI-generated information.

---

## Conventions

### Page naming
- Events: `YYYY:EventName` (e.g. `2026:FOSSMeet`, `2026:Tathva`)
- Subpages: `YYYY:EventName/Schedule`, `/Speakers`, `/Team`, `/Roadmap`, `/Gallery`, `/Coverage`
- People: `Firstname Lastname` (main namespace)
- Places: `Place Name` (main namespace)
- Clubs: `ClubName` (main namespace, e.g. `FOSSCell`)

### Templates
- `{{Infobox FOSSMeet}}` — event infobox (40+ fields, all optional)
- `{{FOSSMeet Tabs}}` — subpage navigation (auto-detects base page)
- `{{FOSSMeet Navbox}}` — all-editions bottom nav
- `{{FOSSMeetTeam}}` — team roster

### Categories
- `[[Category:FOSSMeet]]` — all FOSSMeet pages
- `[[Category:FOSSMeet YYYY]]` — per-edition (auto-added by infobox)
- `[[Category:Events]]` — all events
- `[[Category:FOSSMeet Speakers]]` — speaker pages
- `[[Category:FOSSMeet Teams]]` — team pages
