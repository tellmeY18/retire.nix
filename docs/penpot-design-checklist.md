# amban.io v2 "Onyx" — Design Build Checklist

**File:** `pot.tellmey.fyi` → `amban.io`
**Quality page:** `v2 · Onyx · Home [Quality]`
**Principle:** One thing at a time. Verify visually. No rushing.

---

## Status Key

- `[ ]` Not started
- `[~]` In progress
- `[✓]` Done & verified visually
- `[!]` Blocked / needs input

---

## Phase 0 · Foundation (token system, icon set, reusable helpers)

- [✓] Colour tokens registered (29 tokens in `amban.onyx` set)
- [✓] Library palette colours (27 named colours)
- [✓] Typography styles (11 registered in library)
- [✓] Apply tokens to shapes via `shape.applyToken()` — 14 shapes token-bound
- [✓] Lucide icons inserted as real SVG via `createShapeFromSvg` (bell, house, pencil-line, chart, settings, wallet)
- [ ] Commit Lucide icon SVG subset to repo (`design/lucide.json`) — for future screens
- [✓] Validate ₹ glyph at all weights — confirmed working
- [✓] Register spacing tokens (10 dimension tokens: 4–72dp)
- [✓] Register radius tokens (6: chip, card, cardLg, sheet, fab, pill)

---

## Phase 1 · Home Screen — Hero (current iteration)

### 1.1 Structure & layout
- [✓] Screen frame: 412×892, true black `#000000`
- [✓] StatusBar: 28dp, time + signal + battery
- [✓] TopAppBar: 56dp, left-aligned greeting, bell icon + notif dot
- [✓] DateRow: body-md, secondary
- [✓] ScoreCard glow aura: layer-blur 56px, 18% mint
- [✓] ScoreCard: 372×216, elevated-1 bg, 20px radius, 1px border
- [✓] PendingIncome eyebrow + swipeable row
- [✓] DailyLogPrompt card
- [✓] Upcoming Bills: 3 horizontal chips, colour-coded due pills
- [✓] InsightCard with carousel dots
- [✓] BottomNav: 4 tabs, Home active (chartreuse pill + icon)
- [✓] Gesture annotations (↓ pull, ◉ long-press, → swipe, ← swipe, ◀▶ pan)

### 1.2 Polish pass (next)
- [✓] Convert ScoreCard to a real `LibraryComponent` with variants
- [✓] Apply auto-layout (FlexLayout) to each BillChip (column, 12dp padding, 4dp gap)
- [ ] Apply auto-layout to ScoreCard internals (requires restructuring into sub-groups)
- [ ] Apply auto-layout to PendingIncomeRow internals (requires sub-grouping)
- [ ] Apply auto-layout to BottomNav (requires tab sub-groups)
- [✓] Replace all icon circles with actual Lucide SVG paths:
  - [✓] Bell (`bell`)
  - [✓] Home tab (`house`)
  - [✓] Log tab (`pencil-line`)
  - [✓] Insights tab (`chart-no-axes-column-increasing`)
  - [✓] Settings tab (`settings`)
  - [✓] Income icon (`wallet`)
- [✓] Validate 4dp grid snapping on every element (85 shapes → 35 fixed → 0 remaining)
- [✓] Validate containment (0 overflows across 11 boards)
- [ ] Add UpdateBanner (app version strip — optional, only when update available)
- [ ] ScoreCard pressed state (96% scale, 0.92 opacity) — separate frame
- [✓] ScoreCard long-press reveal state — breakdown math frame (below Home)

### 1.3 ScoreCard variant builds
- [✓] ScoreCard / Healthy (promoted to LibraryComponent, main instance on Home)
- [✓] ScoreCard / Watch (amber number, amber pill, amber glow)
- [✓] ScoreCard / Critical (salmon number, salmon pill, salmon glow)
- [✓] ScoreCard / Loading (disabled colour, ··· placeholder)
- [✓] All 4 combined into VariantContainer with `state` property axis

### 1.4 Paper (light) variant of Home
- [✓] Duplicate Home frame → renamed `07 · Home · Paper`
- [✓] Swap all tokens to Paper equivalents (41-colour recursive recolour)
- [✓] Add real shadows (drop-shadow: 0 2 8 rgba(10,10,18,0.06) on cards, 0 4 16 on ScoreCard)
- [✓] Remove glow aura (hidden — Onyx-only effect)
- [ ] Verify colour contrast ratio on key elements (WCAG AA)

---

## Phase 2 · Onboarding Screens (01–06)

- [ ] 01 · Welcome — logo, tagline, preview card, CTA, microcopy
- [ ] 02 · Name + Emoji — progress dots, title, emoji grid, input, CTA
- [ ] 03 · Income Sources — progress, added rows, add button, total
- [ ] 04 · Bank Balance — hero input card, quick chips, privacy card
- [ ] 05 · Recurring Payments — bill rows, total card, "left to spend" pill
- [ ] 06 · Score Reveal — confetti, oversized ScoreCard, glow hero moment

Each screen must:
- [ ] Use the same BottomNav component (inactive — onboarding has no nav)
- [ ] Use the same StatusBar component
- [ ] Have a Paper variant below it
- [ ] Pass 4dp grid validation
- [ ] Pass containment validation

---

## Phase 3 · Main App Screens (08–14)

- [ ] 08 · Daily Log — amount input, cursor, quick chips, entry list, CTA
- [ ] 09 · Log History — bar chart, filter chips, day-grouped entries
- [ ] 10 · Add Income Sheet — bottom sheet, currency input, label, date
- [ ] 11 · Insights — spend chart, stats row, 3 insight cards
- [ ] 12 · Settings — profile card, finance/prefs/data rows, footer
- [ ] 13 · Manage Income — filter, swipeable rows, add FAB
- [ ] 14 · Manage Recurring — rows with paid state, swipe-to-mark-paid

---

## Phase 4 · Sheets & System (15–19)

- [ ] 15 · BalanceUpdateSheet — medium bottom sheet, currency input
- [ ] 16 · EntrySheet — expanded sheet, category chips, notes, time
- [ ] 17 · ConfirmDaySheet — summary, delta pill, notes, confirm CTA
- [ ] 18 · MigrationFailed — error state, 3 action buttons, disclosure
- [ ] 19 · Style Guide — all components in both themes, swatches, type ramp

---

## Phase 5 · Component Library (extracted after screens stabilise)

- [ ] ScoreCard (4 variants) → `LibraryComponent`
- [ ] PendingIncomeRow (3 states) → `LibraryComponent`
- [ ] RecurringPaymentRow (3 states) → `LibraryComponent`
- [ ] QuickAmountChip (default / pressed / long-press) → `LibraryComponent`
- [ ] BottomSheet (peek / medium / expanded) → `LibraryComponent`
- [ ] PrimaryCTA (default / pressed / disabled / loading) → `LibraryComponent`
- [ ] TopAppBar (default / scrolled) → `LibraryComponent`
- [ ] BottomNav (per-tab active state) → `LibraryComponent`
- [ ] InsightCard (info / positive / warning) → `LibraryComponent`
- [ ] StatusPill (healthy / watch / critical / neutral) → `LibraryComponent`

---

## Phase 6 · Documentation Panels

- [ ] Gesture Map (7 gestures, glyph + label + where-used)
- [ ] Motion Specs (8 animations, element + duration + curve + note)
- [ ] Before/After frame (M3 Violet Home vs Onyx Home side-by-side)

---

## Phase 7 · Final Validation

- [ ] All 19 Onyx screens pass 4dp grid check
- [ ] All 19 Paper variants exist and are colour-correct
- [ ] All 10 components are registered as LibraryComponents
- [ ] Tokens are applied (not hardcoded) on at least the Home screen
- [ ] Every screen has gesture annotations
- [ ] Every animated element has a timing chip
- [ ] ₹ renders correctly in display-xl (72dp) — verified
- [ ] No element overflows its parent board
- [ ] Layer naming is semantic (no "Rectangle 42" etc.)

---

## Process Rules (non-negotiable)

1. **One section per session.** Build → visually verify → iterate → move on.
2. **Export after every section.** If export times out, ask the user to verify in-browser.
3. **No ASCII fallbacks.** If a glyph fails, debug the API call. Don't substitute.
4. **Auto-layout before content.** Create the Board with FlexLayout *first*, then add children.
5. **Real components before screen duplication.** Extract to LibraryComponent before making variants.
6. **Tokens over hex literals.** Once tokens exist for a value, use `shape.applyToken()`.
7. **Fix forward, not around.** If a Penpot API call fails, check the API docs and retry correctly.
