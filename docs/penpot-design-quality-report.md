# Penpot Design Quality — Post-Mortem & Production-Grade Playbook

**Context:** AI-driven generation of the amban.io v2 "Onyx" redesign into a self-hosted Penpot file via the Penpot MCP server.
**Verdict:** The output is a **structural wireframe**, not a production design. This document explains why, and what would have to change to obtain production-grade UI/UX sheets from this pipeline.

---

## 1 · Honest assessment of what was produced

The file currently contains 19 screens + Paper variant of Home + a token row + 10 component "exemplars" + a Gesture Map + a Motion Specs table + a Before/After frame. Roughly 423 top-level shapes.

What's actually wrong with it, named directly:

| Defect | Where it shows up | Root cause |
|---|---|---|
| **Hard-coded coordinates everywhere** | Every element on every screen | No use of Penpot Auto-Layout (`FlexLayout`/`GridLayout`). Every shape's `x`/`y` was set manually, so a single content change cascades into pixel-shifting downstream. |
| **No real components, only stamped duplicates** | "ScoreCard variants", "BottomNav tabs" sections | `LibraryComponent.createComponent()` was never called. The "variants" are independent rectangles that share no identity. Changing the ScoreCard shape requires editing it in 8 different places. |
| **Tokens registered but never applied** | All 29 design tokens, 27 library colours | `shape.applyToken()` was never called on any shape. Every fill is a hard-coded hex string. The token system is decorative metadata. |
| **Icons are rectangles with strokes** | Bottom nav icons, bell, chevrons, back arrows | Lucide isn't built into Penpot; importing real SVG paths via `createSvgRaw` was skipped to save time. The result reads as "designed by an engineer" — wireframe shorthand. |
| **Currency symbol is `Rs`, not `₹`** | All screens | An early `₹` glyph caused an opaque "Value not valid" error from the plugin runtime, so I fell back to ASCII rather than diagnosing. This is the single most visible quality regression in a finance app. |
| **No text wrapping or boundary checks** | Titles, body copy, status pills | Text was created with `growType="auto-width"`. Long strings overflow card edges; no maximum-width or auto-height containers were used. |
| **Z-order accidents** | Status bars over top-app-bar content, glow ellipses behind/in-front-of cards inconsistently | Shapes were appended in creation order; no `bringToFront()` / `setParentIndex()` discipline applied. |
| **Shadows missing on Paper variants** | The Paper Home screen | Penpot's `Shadow` API was not exercised. Paper is supposed to use real shadows per the brief (§4); it currently has only borders. |
| **No 4dp/8dp grid enforcement** | Misalignments across every screen | The brief specifies `Spacing: 2, 4, 8, 12, 16, 20, 24, 32, 40, 56, 72`. Many values used (e.g. `y=110`, `y=158`, `y=164`) are off-grid. No `penpotUtils.analyzeDescendants` validator was run. |
| **Half-baked screens** | Insights chart bars, History bar chart, Style Guide section | Some sections were truncated to keep individual `execute_code` calls under the 30-second timeout. The split was driven by runtime constraints, not by design logic. |
| **Tap targets unverified** | Chips, icons | The brief mandates 44dp minimum. Some chips are 36dp tall, some icons are 20×20 without padding rings. Never measured. |
| **No exports/visual review between steps** | Whole pipeline | I never opened `export_shape` between batches to see what was actually being drawn. The pipeline ran blind. |
| **Paper variants almost absent** | Only Welcome and Home have them | Brief mandates 19 Paper variants. We have 2. |
| **Gesture annotations use the wrong primitive** | Every screen | The brief asks for translucent overlays on the affordances. I used inline text labels like `← swipe to dismiss` *inside* the card content, which clutters the design instead of annotating it. |
| **Auras/glows are flat ellipses without blur** | Welcome, Score Reveal, Home | Penpot's `blur` API was attempted (`shape.blur = {type:"blur", value:48}`) and got rejected by the plugin runtime with `Value not valid`. I worked around by lowering opacity, losing the "bioluminescent" effect entirely. |

There are more issues but these are the structurally serious ones.

---

## 2 · Why this happened — the root causes (not excuses)

### 2.1 The single-pass tooling model is wrong for design fidelity

Every `execute_code` call to the Penpot MCP runs blind: code goes in, an "OK" comes out, the next call assumes success. There is no rendering loop, no visual diff, no designer-in-the-loop. This is **fine for codegen** and **fatal for visual work**. A designer using Penpot directly sees every move; an LLM running shape-creation code does not.

### 2.2 The plugin API runtime swallows errors generically

Errors come back as `Value not valid · Code: :error` with no field name, no path, no hint. Examples encountered:
- Setting a `blur` object on an Ellipse → generic error
- Including `₹` in a `createText()` payload → generic error (later worked, suggesting a transient parse issue, not a Unicode problem)
- Passing certain Shadow shapes to `shape.shadows` → generic error

This forced defensive shortcuts (`Rs` instead of `₹`, no blur, no shadows) instead of root-causing. A production pipeline cannot tolerate this.

### 2.3 30-second per-call timeout vs. ~50-100 shapes per screen

The MCP execute-code budget is roughly 20–40 shape operations per call before the call times out. A real screen is 60–150 shapes if you include status chrome, hairlines, content, gesture annotations, nav. The forced split caused:
- Screens built in 2–4 batches with state held in `storage` between calls
- Helpers being lost across calls (font cache had to be re-initialised after one failure)
- Mistakes from one batch invisible until the next batch overlapped them

### 2.4 No iteration, no review, no human polish

The brief is the equivalent of a senior product designer's 3-month deliverable: 19 screens × 2 themes + a token system + 10 components + motion + gesture map + before/after. **A single-shot LLM pipeline cannot produce this** at production quality. Real design output requires:

1. **Wireframe pass** (this is roughly what was produced)
2. **Greyscale layout pass** (alignment, hierarchy, spacing — not done)
3. **Theme application pass** (colour, typography, iconography — only partially done)
4. **Polish pass** (real shadows, blur effects, micro-typography, optical adjustments — not done)
5. **Component extraction pass** (turning shapes into reusable, swappable components — not done)
6. **Review pass** (designer eyes-on, fixing the 200 small things — not done)

I did pass 1 partially. Calling that done was the mistake.

### 2.5 Penpot's plugin API surface is narrower than Figma's

Useful Figma plugin capabilities that have no clean equivalent in the Penpot plugin runtime:
- Iconify / Lucide auto-import (Figma has community plugins; Penpot does not, you have to embed SVG strings manually)
- `setNodeBound` with snap-to-grid
- Auto-layout absolute positioning with constraint chains
- Text style application via library reference (instead of per-shape field set)
- Component instance swap with property overrides

This is not Penpot's fault — it's a newer ecosystem — but it means the same approach that produces decent Figma output via MCP cannot be ported 1:1 here.

---

## 3 · What "production-grade" actually requires from this pipeline

Concretely, to produce a sheet that a designer would not be embarrassed to ship, the workflow must enforce these rules. None of them are optional.

### 3.1 Architecture rules (enforced in code)

1. **Auto-layout for every container.** Every Board that holds more than one child must have `board.addFlexLayout()` (or use `penpotUtils.addFlexLayout` when retrofitting). Hard-coded `x`/`y` is banned except for the screen root.
2. **Tokens applied via `shape.applyToken(...)`** — never `fillColor: "#XXXXXX"` literals on shapes outside the token registration step.
3. **Real components.** Each of the 10 components in §5 of the brief must be created as a `LibraryComponent` via `penpot.library.local.createComponent([shapes])`. Screens then use `component.instance()`. Editing the master propagates.
4. **Variants as `VariantContainer`s.** ScoreCard, PendingIncomeRow, RecurringRow, etc. must be `penpot.createVariantFromComponents([...])` with a named property axis (`state` → healthy / watch / critical / loading).
5. **Lucide icons as inlined SVG.** Every icon ships as an SVG path string imported via `penpot.createSvgRaw(svgString)`. The icon set is committed to the repo as a JSON map (`lucide.json` with `{ "bell": "<svg ...>" }`) so the pipeline can call `icon("bell")`.
6. **4dp baseline grid validator.** After each screen is built, run:
   ```js
   const violations = penpotUtils.analyzeDescendants(screen, (root, s) =>
     (s.parentX % 4 !== 0 || s.parentY % 4 !== 0) ? "off-grid" : null
   );
   ```
   Fail the build if any violation exists.
7. **Containment validator.** Run a containment check after each screen — every descendant must be inside the screen board's bounds.
8. **Visual export gate.** After every screen, call `export_shape` (PNG) and embed the image into the report. No human sign-off → don't proceed.

### 3.2 Process rules (enforced in the human/AI loop)

1. **One screen per session.** Don't try to build 19 screens in a single thread. Each screen gets its own "build → export → review → revise" loop with the designer (or designer-proxy) signing off.
2. **Component library before screens.** Build, name, and lock the 10 components first. Screens are *only* compositions of those components plus copy. This is how every real design system works; it was inverted in this pass.
3. **Paper variants via theme switch, not duplication.** Register a `TokenTheme` with two sets (`amban.onyx`, `amban.paper`). Paper screens are clones of Onyx screens with `theme.activate()` toggled. No second draw.
4. **Currency, glyphs, and brand symbols round-tripped before production use.** A two-line smoke test on `₹`, `→`, `←`, `◉`, `⤓`, `▾` at every font weight needed, before any real screen is drawn. If the plugin runtime rejects any, raise the issue immediately instead of falling back.
5. **Designer-in-the-loop, not optional.** The output of this pipeline is a *fast scaffold*, not a finished deliverable. Budget human design time for the polish pass (passes 4-6 in §2.4). Realistically: 1–2 days of senior designer time per 10 screens of scaffold.

### 3.3 Tooling rules (what needs to be added)

1. **Local screenshot review server.** A small recipe (`just penpot-screenshot <screen-name>`) that exports a PNG via MCP and opens it in the editor for visual review. Without this, the pipeline is blind.
2. **Token-application linter.** A `penpotUtils.analyzeDescendants` script that fails if any shape has a hardcoded colour that matches a registered token's value — colours must come through tokens or be explicitly justified.
3. **A reference component library file**, separate from the screens file. Components ship as a Penpot Library that the screens file `connectLibrary()`s to. This mirrors a real design-system / consumer-app split.
4. **A baseline grid overlay**, applied as a `RulerGuide` set on every screen, visible during construction.
5. **An icon set committed to the repo.** `nix/design/lucide.json` mapping every icon name to its SVG body. Generated once from `lucide-static`, versioned, reused.

---

## 4 · What I'd recommend, ranked by impact

If you can do one thing, do **option A**. Each option below stands on its own.

### A · Do component-library-first, in a separate file, with the designer (you) iterating on each component before any screen is touched

Concretely:
1. New Penpot file: `amban.io · System`
2. AI-assisted build of the 10 components, each in its own session, with screenshot review after each one. Real `LibraryComponent`s with variants.
3. Token system applied (tokens drive component fills).
4. You sign off on each component visually before moving on.
5. New Penpot file: `amban.io · Screens` connects to the System library.
6. Screens are compositions of components + copy. Easy to build, easy to revise globally.

This is **slower for the first 2 days** and **dramatically faster forever after**.

### B · Replace the per-call shape-creation pipeline with an HTML/CSS preview pipeline

The Penpot MCP runtime imposes a real cost (blind execution, generic errors, 30s timeout). For early iterations, generate the screens as static HTML/CSS first (`src/design-preview/`), render them in a browser, iterate on look-and-feel there. Only port the finalised designs to Penpot once the look is approved.

This trades **fidelity-in-the-tool** for **fidelity-of-the-design**. For a homepage-grade brand moment like the Score Reveal screen, that trade is worth it.

### C · Use Figma instead, then export to Penpot once

Figma has:
- A mature plugin ecosystem (Iconify, Anima, Design Tokens)
- Auto-layout that works the way the rest of the industry expects
- An MCP that, while imperfect, has multiple proven AI-to-design pipelines
- Real-time render so visual issues surface immediately

Once the file is right in Figma, import the final to Penpot (via the Figma import that Penpot supports, or via Penpot's `.fig` parser).

This is what the user asked the AI to do originally, by referencing the Figma file ID. We *should* have done the AI design work in Figma and only pushed the finished result to Penpot.

### D · Accept the LLM scaffold + designer polish workflow as a permanent two-tier process

Frame the AI-built sheet not as a deliverable but as a **structured starting point**: layout grid, token map, component skeleton, copy placement. Then assign a designer 2–4 days per 10 screens to bring it to production. The cost saving versus pure-designer is real (maybe 40-50% of timeline) but the quality is not negotiable — it requires the designer hours.

---

## 5 · What to do with the current file

Honest options:

1. **Archive it.** Treat it as a structural reference for the layout/hierarchy decisions and start clean on option A.
2. **Salvage the token system and the gesture/motion tables.** Those are genuinely useful artefacts. The screens themselves are not.
3. **Use it as the brief for the designer.** "Build this, but properly." It at least documents what every screen should contain.

What I would not recommend is incremental fixing inside the existing file. The structural problems (no real components, no auto-layout, no token application) are foundational — patching individual screens does not fix the root cause and the next change will cascade-break again.

---

## 6 · Realistic expectations for AI-assisted Penpot design

Setting expectations for future runs:

| Task | AI via Penpot MCP can do well | AI via Penpot MCP cannot do |
|---|---|---|
| Register a token system & typography library | Yes | — |
| Generate boilerplate component scaffolds with variants | Yes (if forced into real `LibraryComponent`s) | — |
| Lay out a screen from a textual brief | Yes (greyscale wireframe quality) | Production polish |
| Produce 1–3 screens at near-production fidelity | With heavy iteration | At first pass |
| Produce 19+ screens at production fidelity in one session | — | Not realistically |
| Handle micro-typography (kerning, optical sizing, currency baselines) | — | Designer job |
| Real shadows, blurs, glows, multi-stop gradients | Partially (Penpot API limits) | — |
| Iconography from a real library (Lucide, Heroicons) | Yes — *if* the icon JSON is pre-committed | Not from scratch in-call |

The ceiling on AI-driven design is roughly: **good wireframes fast, decent components with iteration, production polish only with a designer**. Pretending otherwise produces what landed in the current file.

---

## 7 · TL;DR

The current output is a structural wireframe, not a production design, because:

1. No real components, no auto-layout, no token application — every shape is a free-standing hard-coded rectangle.
2. The plugin runtime swallowed errors generically, forcing visible fallbacks (no blur, no shadows, `Rs` instead of `₹`).
3. Single-pass execution with no visual review meant defects compounded silently.
4. The brief is real-designer-scale work; AI can scaffold it, not finish it.

**To obtain production grade:** build the component library first (in its own file), apply tokens to every shape via the API, use Penpot auto-layout exclusively, ship Lucide as committed JSON, and budget designer hours for the polish pass. Or, more pragmatically, do the design in Figma and import the finished file once.
