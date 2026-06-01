# PageForms Migration Plan — wiki.fosscell.org

> **Status:** ✅ Forms complete — all 13 core forms live and category-linked (2026-06-01)
> **Depends on:** Phase 4 (Templates) from ROADMAP.md — templates already exist
> **Extensions required:** PageForms ✅, PageSchemas ✅, Cargo ✅ (all loaded, build-55)
>
> **Live forms:** Centre, Club, Home Team, Home Team Year, Campus Location,
> Centre Year Report, CCD Year Report, Hostel, Course, Person, Faculty,
> Event, SAC Meeting. Each is linked to its category via `{{#default_form:}}`
> so existing pages show an "Edit with form" tab — verified rendering with
> mandatory fields + dropdowns. Remaining: FOSSMeet form, TemplateData JSON,
> PageSchemas, Cargo autocomplete.

---

## Overview

Replace all `/preload` templates with proper PageForms form definitions. Users will create/edit pages via GUI forms instead of editing raw wikitext.

**What stays:** All `Template:Infobox *` templates (they render the display)
**What gets replaced:** All `Template:*/preload` pages → `Form:*` pages
**What gets added:** `#default_form` on category pages so "Edit with form" tab auto-appears

---

## Current Templates → Forms Mapping

| Existing Template | Preload (to retire) | New Form Page | Category Auto-link |
|---|---|---|---|
| `Template:Infobox Centre` | `Template:Infobox Centre/preload` | `Form:Centre` | `Category:Multidisciplinary Centres` or `Category:Thematic Centres` |
| `Template:Centre Year Report` | `Template:Centre Year Report/preload` | `Form:Centre Year Report` | `Category:Annual Reports` |
| `Template:CCD Year Report` | `Template:CCD Year Report/preload` | `Form:CCD Year Report` | `Category:Placement Reports` |
| `Template:Infobox Club` | `Template:Infobox Club/preload` | `Form:Club` | `Category:Clubs and Organizations` |
| `Template:Infobox Home Team` | `Template:Infobox Home Team/preload` | `Form:Home Team` | `Category:Home Teams` |
| `Template:Infobox Home Team Year` | `Template:Infobox Home Team Year/preload` | `Form:Home Team Year` | `Category:Home Teams` |
| `Template:Infobox Campus Location` | `Template:Infobox Campus Location/preload` | `Form:Campus Location` | `Category:Campus Locations` |
| `Template:Infobox Hostel` | `Template:Infobox Hostel/preload` | `Form:Hostel` | `Category:Hostels` |
| `Template:Infobox Course` | `Template:Infobox Course/preload` | `Form:Course` | `Category:Courses` |
| `Template:Infobox Person` | `Template:Infobox Person/preload` | `Form:Person` | `Category:People` |
| `Template:Infobox Faculty` | `Template:Infobox Faculty/preload` | `Form:Faculty` | `Category:Faculty` |
| `Template:Infobox Event` | — | `Form:Event` | `Category:Events` |
| `Template:Infobox FOSSMeet` | — | `Form:FOSSMeet` | `Category:FOSSMeet` |
| `Template:Infobox SAC Meeting` | — | `Form:SAC Meeting` | `Category:SAC Meetings` |
| `Template:Infobox Building` | — | `Form:Building` | `Category:Buildings` |

---

## Execution Plan

### Phase A — Core Infrastructure Forms (do first)

These are the highest-traffic templates. Get these right and the pattern is set.

#### A1. `Form:Club`

**Priority:** Highest (20-30 pages)
**Fields:**
- name (mandatory, text)
- image (text)
- caption (text)
- fullname (text)
- shortname (text)
- type (dropdown: Technical, Cultural, Literary, Sports, Social, Other)
- founded (year input)
- parent_org (text)
- faculty_advisor (text with autocomplete from Category:Faculty)
- affiliated_with (text)
- flagship_event (text)
- teams (textarea)
- member_count (number)
- description (textarea)
- website (URL)
- instagram (text)
- telegram (text)
- github (text)
- email (text)
- status (dropdown: Active, Inactive, Defunct)

**Free text sections:** About, Events, Notable Members, History

**Category auto-add:** `[[Category:Clubs and Organizations]]`
**Default form link:** Add `{{#default_form:Club}}` to `Category:Clubs and Organizations`

---

#### A2. `Form:Centre`

**Priority:** High (33 pages — just created all these)
**Fields:**
- name (mandatory, text)
- image (text)
- shortname (text)
- established (year input)
- chairperson (text)
- type (dropdown: Multidisciplinary Centre, Thematic Centre)
- website (URL)
- email (text)
- contact (text)
- description (textarea)

**Free text sections:** About, Vision and Mission, Activities, Yearly Reports

**Category logic:** Auto-categorize based on `type` field:
- `Multidisciplinary Centre` → `[[Category:Multidisciplinary Centres]]`
- `Thematic Centre` → `[[Category:Thematic Centres]]`

---

#### A3. `Form:Home Team`

**Priority:** High (active yearly cycle)
**Fields:**
- name (mandatory)
- image, logo, caption (text)
- type (dropdown: Cultural, Technical, Sports)
- discipline (text)
- founded (year)
- founder (text)
- batch_size (text)
- induction_year (text)
- current_lead (text)
- faculty_advisor (text)
- meeting_place (text)
- parent_fest (text with autocomplete)
- achievements_count (number)
- instagram (URL)
- website (URL)

**Free text sections:** About, Yearly Reports, Achievements, See also

---

#### A4. `Form:Home Team Year`

**Priority:** High (yearly reports)
**Fields:**
- team (text, pre-filled from context)
- year (text)
- batch (text)
- captain (text)
- members (textarea)
- achievements (textarea)
- project (text)
- image (text)

**Free text sections:** Season Summary, Performances, Achievements

---

### Phase B — Academic & Administrative Forms

#### B1. `Form:CCD Year Report`

**Priority:** High (annual placement data)
**Fields:** All 30+ fields from `Template:CCD Year Report` (year, data_as_of, companies_visited, total_offers, ug/pg breakdowns, salary stats, etc.)

**Input types:**
- Salary fields: number inputs
- Percentage fields: number inputs
- notable_companies: tokens (comma-separated with autocomplete)
- year: text (e.g. "2024-25")

**Free text sections:** Overview, Placement Statistics (UG/PG subsections), Internship Statistics, Recruiting Companies, Programme-wise Breakdown

---

#### B2. `Form:Centre Year Report`

**Fields:** centre, year, chairperson, activities, achievements, events, collaborations, publications

---

#### B3. `Form:Course`

**Fields:** name, code, department (dropdown from departments), credits, semester, prerequisites, instructor, description

---

#### B4. `Form:Faculty`

**Fields:** name, image, department (dropdown), designation (dropdown: Professor, Associate Professor, Assistant Professor), specialization, email, website, phone

---

### Phase C — Campus & Events Forms

#### C1. `Form:Campus Location`

**Fields:** name, image, type (dropdown: Academic, Residential, Recreation, Administrative, Religious, Commercial), campus (dropdown: Main Campus, Hostels Area, Staff Quarters), also_known_as, established, area, floors, capacity, departments, facilities, hours, website, status, adjacent_to, houses, built, coordinates

---

#### C2. `Form:Hostel`

**Fields:** name, image, type, capacity, warden, location, facilities, established

---

#### C3. `Form:Event`

**Fields:** name, image, date, venue, organizer, type (dropdown: Technical, Cultural, Sports, Academic), description, website

---

#### C4. `Form:FOSSMeet`

**Fields:** edition, year, dates, venue, theme, convener, registration_count, talks_count, workshops_count, website, logo

---

#### C5. `Form:SAC Meeting`

**Fields:** meeting_number, date, venue, chairperson, secretary, attendees_count, key_decisions (textarea), minutes_link

---

### Phase D — People Forms

#### D1. `Form:Person`

**Fields:** name, image, batch, branch, notable_for, current_role, linkedin, github, website

---

---

## Implementation Steps (for each form)

### Step 1: Add `#template_params` to the template

Each template needs its parameters declared for PageForms to discover them. Add to the `<noinclude>` section:

```mediawiki
{{#template_params:
| name | type=string | label=Name
| shortname | type=string | label=Short Name
| established | type=number | label=Year Established
...
}}
```

### Step 2: Create the Form page

Create `Form:<Name>` with the PageForms form definition syntax.

### Step 3: Link form to category

Add `{{#default_form:FormName}}` to the relevant category page so the "Edit with form" tab appears on all pages in that category.

### Step 4: Test

- Create a new page using the form
- Edit an existing page using "Edit with form" tab
- Verify all fields populate correctly

### Step 5: Retire preload

Mark `/preload` pages as deprecated (don't delete — they're harmless and serve as documentation).

---

## Category → Form Linkage

Add `{{#default_form:...}}` to these category pages:

| Category | Default Form |
|---|---|
| `Category:Clubs and Organizations` | `Form:Club` |
| `Category:Multidisciplinary Centres` | `Form:Centre` |
| `Category:Thematic Centres` | `Form:Centre` |
| `Category:Home Teams` | `Form:Home Team` |
| `Category:Campus Locations` | `Form:Campus Location` |
| `Category:Hostels` | `Form:Hostel` |
| `Category:Faculty` | `Form:Faculty` |
| `Category:Courses` | `Form:Course` |
| `Category:Events` | `Form:Event` |
| `Category:FOSSMeet` | `Form:FOSSMeet` |
| `Category:Placement Reports` | `Form:CCD Year Report` |
| `Category:Annual Reports` | `Form:Centre Year Report` |

---

## Quick Wins (can do immediately)

1. **`Form:Centre`** — 33 pages already use `{{Infobox Centre}}`. Create the form, add `{{#default_form:Centre}}` to both centre categories. Instant "Edit with form" tab on all centre pages.

2. **`Form:Club`** — 20+ pages already use `{{Infobox Club}}`. Same approach.

3. **`Form:Home Team`** — Active use with yearly reports.

---

## Timeline

| Week | Action |
|---|---|
| 1 | Create Form:Club, Form:Centre, Form:Home Team (core 3) |
| 1 | Add `{{#default_form}}` to their categories |
| 2 | Create Form:CCD Year Report, Form:Centre Year Report |
| 2 | Create Form:Campus Location, Form:Hostel |
| 3 | Create Form:Course, Form:Faculty, Form:Person |
| 3 | Create Form:Event, Form:FOSSMeet, Form:SAC Meeting |
| 4 | Test all forms, fix edge cases, document |

---

## Notes

- **Existing pages don't need editing** — PageForms reads existing template calls and populates the form fields automatically when you click "Edit with form"
- **Preloads can coexist** — forms are strictly better UX but preloads still work for power users who prefer wikitext
- **Cargo integration** — PageForms autocomplete works with Cargo tables. As we add Cargo declarations to templates, form fields get smart autocomplete for free
- **Year namespace forms** — For forms used in year namespaces (Home Team Year, Centre Year Report, CCD Year Report), the form's `{{{info}}}` tag needs `page name=<Year>:<PageName>` formula
