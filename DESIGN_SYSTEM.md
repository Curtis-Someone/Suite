# Suite — Design System

Extracted from the Claude Design handoff: project `95c86801-01b8-428d-b6c4-2aec876f97b2`,
file **`Suite Screens Light.dc.html`** (the definitive file per Ivan), primarily the
style-sheet artboard *"12 · Style sheet"* plus values read directly off the 37 screen
artboards.

**Canonical form:** `Suite/Shared/Theme/Theme.swift` + `Typography.swift`. This document
is the human companion — update both together. Where this file and the `.dc.html` ever
disagree, the `.dc.html` wins.

The design canvas renders phone artboards at **390 × 844** (iPhone 14/15 logical size)
with a 46 pt device-frame radius. That radius is canvas chrome only — do not apply it to
real views. All artboards are **portrait**.

---

## 1. Palette — light + dark, single amber accent

The app follows the **system appearance** (default light). Every token is
adaptive — `Color(light:dark:)` in `Theme.swift`. Light values from
`Suite Screens Light.dc.html`, dark from `Suite Screens.dc.html`
("near-black base"). Dark shades are calibrated from the dark style-sheet
artboard's six swatches and refined per screen as batches build against the
dark artboards.

| Token (`Theme.Palette`) | Light | Dark | Role |
|---|---|---|---|
| `ground` | `#F5F3EF` | `#0F0F10` | App background behind every screen |
| `surface` | `#FFFFFF` | `#141415` | Raised screen, primary card |
| `surfaceSunken` | `#F4F1EC` | `#1A1A1B` | Inset card fill — stat cards, grouped rows |
| `panel` | `#F1EEE8` | `#1A1A1B` | Onboarding-tour hero panel |
| `fill` | `#EFEBE3` | `#1F1F20` | Subtle fill (chips at rest) |
| `fillStrong` | `#EAE6DF` | `#232325` | Stronger fill / nav hairline zone |
| `border` | `#E4E0D9` | `#232323` | Hairline border |
| `divider` | `#E2DED7` | `#2A2A2C` | Divider inside a sunken card |
| `track` | `#E0DCD4` | `#2E2E30` | Progress-bar track, inactive toggle |
| `accent` | `#D09A42` | `#D09A42` | The one accent (unchanged both modes) |
| `accentHigh` | `#E8B75F` | `#E8B75F` | Link hover / pressed emphasis |
| `onAccent` | `#0A0A0A` | `#0A0A0A` | Text/glyph on an amber fill (amber stays light) |
| `textPrimary` | `#0A0A0A` | `#FFFFFF` | Primary text, display, CTA label on amber |
| `textHeading` | `#14161A` | `#F2F0EC` | Dark-chrome text, line-icon strokes |
| `textBody` | `#4A4740` | `#C9C4BC` | Body-strong |
| `textSecondary` | `#77736C` | `#8A857E` | Secondary copy |
| `textTertiary` | `#8F8B84` | `#6E6A64` | Labels, captions, inactive icon stroke |
| `textDisabled` | `#B4B0A8` | `#57534D` | Disabled text |
| `danger` | `#D96A4A` | `#E07C5C` | Destructive ("Log out", "Delete account") |
| `navInk` | `#14161A` | `#F2F0EC` | Floating nav pill — inactive glyphs + active highlight (Asset catalog) |
| `navAmber` | `#97651B` | `#E8B75F` | Nav pill — active tab icon + label; text-safe amber, ~4.5:1 on cream (Asset catalog) |
| `brandAmber` | `#D09A42` | `#D09A42` | `accent` alias as a colour set — large fills / numerals only (Asset catalog) |

**Colour sets vs. code tokens.** Most tokens are `Color(light:dark:)` literals in
`Theme.swift`. The three nav-pill colours are the exception — real `.colorset`s in
`Assets.xcassets` (`NavInk`, `NavAmber`, `BrandAmber`) with dark variants stubbed,
so the v1.1 dark theme is a catalog edit rather than new code. `navHighlight` is
`navInk` at 8% opacity.

The auth-screen hero panel is a fixed `#0A0A0A` in **both** modes (deliberate
night-map treatment).

Single-accent rule holds. **One deliberate exception** (from `CLAUDE.md` + compendium):
full-colour category / flag icons on the Map and suitcase-builder screens carry identity
information and stay multi-colour. Every other icon is monochrome at one stroke weight.

---

## 2. Typography

Families — **Archivo** (display, UI, headings, body, *and* the oversized hero stat
numbers) and **JetBrains Mono** (kicker labels + small tabular data). Both bundled as
variable TTFs in `Suite/Resources/Fonts/`, registered at launch.

> **Conflict with `CLAUDE.md` "numbers are always monospaced":** the handoff sets the
> *big* hero stat numbers in Archivo (proportional) — e.g. `10 / 195`, `5%`, `86%`. Only
> *small inline data* (fractions `7/51`, percentages `14%`) is JetBrains Mono. The handoff
> wins; ramp below reflects it. Flagged for Ivan.

| Style (`Font.Suite`) | Font | Size / line | Tracking | Used for |
|---|---|---|---|---|
| `display` | Archivo 800 | 40 / 1 | −0.03em | Wordmark `Suite.` |
| `statXL` | Archivo 700 | 40 / 1 | −0.03em | Hero stat number (amber); unit suffix ~24pt in `textPrimary` |
| `statL` | Archivo 700 | 30 / 1 | −0.02em | Secondary hero stat |
| `statM` | Archivo 700 | 26 / 1 | −0.02em | Profile / tour stat |
| `titleXL` | Archivo 700 | 30 / 1.15 | −0.02em | Screen title, two lines |
| `titleL` | Archivo 700 | 27 / 1 | −0.02em | Screen title |
| `title` | Archivo 700 | 25 / 1 | −0.02em | Screen title (compact) |
| `titleS` | Archivo 700 | 22 / 1 | −0.02em | Section header |
| `button` | Archivo 700 | 17 / 1 | — | Primary CTA label |
| `bodyL` | Archivo 400 | 15 / 1.55 | — | Body paragraph |
| `body` | Archivo 400 | 15 / 1 | — | Single-line body / list row |
| `bodyStrong` | Archivo 600 | 15 / 1 | — | Emphasised row label |
| `bodyS` | Archivo 400 | 13 / 1.5 | — | Small helper copy |
| `data` | JetBrains Mono 400 | 12 / 1 | — | Fractions, percentages |
| `label` | JetBrains Mono 500 | 11 / 1 | +0.16em, UPPER | Kicker label |
| `labelS` | JetBrains Mono 400 | 10 / 1 | +0.12–0.14em, UPPER | Small kicker / stat caption |
| `micro` | JetBrains Mono 400 | 9 / 1 | +0.10em, UPPER | Swatch caption |

Weights seen: Archivo 400 / 500 / 600 / 700 / 800; JetBrains Mono 400 / 500 / 600 / 700.

---

## 3. Spacing

Observed scale (px): **4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 22 · 24 · 26 · 28 · 32 · 34 · 38 · 44 · 56 · 72**.

Named (`Theme.Space`): `xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · section 44`.
Default horizontal screen inset `screenH = 24` (some screens use 20 or 28 — check the artboard).

Screen chrome: content typically starts ~56–64 px from the top edge; primary CTA sits
~34–44 px from the bottom edge (above the home indicator).

---

## 4. Corner radii (`Theme.Radius`)

| Token | px | Applies to |
|---|---|---|
| `control` | 8 | Colour swatches, tiny controls |
| `chip` / `cardS` | 16 | Filter chips, small cards, search-result rows |
| `card` | 20 | Standard card (stat card, settings group) |
| `cardL` | 22 | Large media card, share preview |
| `fieldGroup` | 18 | Multi-row input group |
| `sheet` | 20 | Bottom-sheet top corners |
| pill | capsule | CTAs, single input fields, toggles, filter chips, nav dots |
| `deviceFrame` | 46 | **Canvas only** — never on a real view |

---

## 5. Component sizing (`Theme.Size`)

| Token | px | Notes |
|---|---|---|
| `cta` | 58 | Full-width primary CTA on a screen (radius = capsule, 29) |
| `ctaCompact` | 54 | CTA inside a form / sheet (radius 27) |
| `field` | 52 | Input row (single fields render 50–56; grouped rows 50–52) |
| `navPill` | 56 | Floating glass nav pill height — capsule, `.ultraThinMaterial`, 0.5px white hairline, soft shadow; 24px side margins, 16px above the bottom safe area |
| `tabIcon` | 28 | Nav-bar icon box (pill glyphs render at 22) |
| `progressBar` | 10 | Track height; radius 5; amber fill; also used per-row at 8px |

Circular gauge: SVG ring, `track` under-stroke + `accent` over-stroke, stroke width ~11–12,
`stroke-linecap: round`, rotated −90°; big number centred in Archivo 700.

---

## 6. Component patterns (from the style-sheet artboard)

- **Primary CTA** — capsule, `accent` fill, `onAccent` label, `Font.Suite.button`.
  On light *form* screens the primary instead uses `textPrimary` fill + white label
  (e.g. "Send reset link", "Log in" in the sign-up sheet).
- **Secondary CTA** — capsule, 1px `textPrimary` outline, `textPrimary` label, Archivo 600.
- **Disabled CTA** — `fillStrong` fill, `textDisabled` label.
- **Segmented toggle** — capsule track in `surfaceSunken`, 4px inset; active segment
  `accent` fill + Archivo 700 `textPrimary`; inactive = Archivo 500 `textSecondary`.
- **Filter chip** — 32px tall, capsule; active `accent` / `onAccent` Archivo 600;
  inactive `surfaceSunken` / `textBody` Archivo 500.
- **Progress bar** — capsule track `track`, capsule `accent` fill; used per-row in
  breakdown lists, not only once at the top.
- **Stat block** — oversized `accent` number (`statXL`/`statL`), small caption beneath;
  always paired with a second stat beside it, never a lone number.
- **Card** — `surfaceSunken` fill, radius 20, padding ~18–20; inner rows divided by 1px
  `divider`.
- **List / result row** — `surface`, radius 16, height ~58–62; leading flag or icon chip
  (30×22, radius 4–5), title, optional sub-label, trailing chevron.
- **Flag chip** — 30×22 (lists) / 34×24 (search); the country's emoji flag
  (`Country.flag`, from Unicode regional-indicator symbols), OS-rendered at ~26pt,
  no fill or border. Selected/visited state reads from the row, not the chip.
  Missing-flag fallback: `track` fill + `textDisabled` glyph.
- **Bottom nav** — floating glass pill (`.ultraThinMaterial` capsule, 0.5px white
  hairline, soft shadow), 3 tabs in order **map · suitcase · passport**. Inactive:
  Lucide glyph only, `navInk` at 55%. Active: glyph **+ label** side by side on a
  `navHighlight` capsule (neutral, colour-independent — like visited/not-visited on
  the Passport), both tinted `navAmber`. Selection change animates `.snappy`,
  suppressed under Reduce Motion. Optional brand-amber badge dot, top-right of a glyph.
- **Selected checkmark** — `accent` filled circle, `onAccent` tick.
- **Toggle switch** — 50×30 capsule; on = `accent` track + white knob; off = `track` +
  `textTertiary` knob.

---

## 7. Icons

**Lucide**, bundled as template SVGs in `Suite/Resources/Assets.xcassets/Lucide/`
(~40 glyphs, stroke nudged from Lucide's native 2.0 → **1.75** on the 24 grid to sit
closer to the canvas `sw`). Accessed via `SuiteIcon` / `SuiteIconView`, which tints with
`.foregroundStyle`. Round caps/joins, no fill.

The bottom-nav tabs are Lucide too — `map` / `luggage` / `book-open`, template-mode
and tinted in code (`BottomNavBar.swift`). The active state is now structural (label
reveal + neutral capsule), so the old bespoke filled-amber glyphs are retired.

Full-colour category / flag icons on Map + suitcase-builder screens are a separate,
deliberate multi-colour exception (§1).

Sizes: `24` standard · `28` nav · `18` inline with text · `16` trailing chevron.

---

## 8. Screen inventory (45 artboards / states in `Suite Screens Light.dc.html`)

**Core flow & tabs:** 01 Splash · 02 Setting up · 03–05 Onboarding tour (map / suitcase /
passport) · 06 Welcome · 07 Log in · 08 Sign up · 08b Where are you from? · 09 Map tab ·
10 Suitcase tab · 11 Passport tab · 12 Style sheet.

**Auth continued:** A1 Forgot password · A2 Check inbox · A3 Location permission ·
A4 Notification permission.

**Global & shared:** G1 Profile · G2 Settings · G3 Search · G4 Share card · G5 Error state.

**Map tab:** M1 Add visits · M2 Country detail · M3 Map view toggle · M4 City detail.

**Suitcase tab:** S1 Suitcase list · S2a New suitcase — basics · S2b New suitcase —
activities · S3 Packing checklist · S4 Trip completed.

**Passport tab:** P1 Trips sub-view · P2 Trip detail · P3 Continent detail · P4 Country list.

**Suite Pro & paywall:** Pro1 Benefits · Pro1-1 Unlimited suitcases · Pro1-2 Templates ·
Pro1-3 Global rank · Pro1-4 iCloud sync · Pro2 Pricing · Pro3 Region detail.
*(Batch 10 — blocked on the `CLAUDE.md` open questions. Pricing on the artboard shows
`$4.99` / `$39.99`, which differs from `CLAUDE.md` `$3.99` / `$24.99` / lifetime — flag
before building.)*

**Reward moments:** R1 packed · R2 trip complete · R3 new country.

---

## 9. Open questions raised by the handoff

1. ~~Monospaced-numbers rule~~ — **RESOLVED**: trust the handoff. Big hero stats in
   Archivo, small inline data in JetBrains Mono. Ramp in §2 stands.
2. **Pro pricing** — **RESOLVED**: use the `CLAUDE.md` pricing (`$3.99/mo`, `$24.99/yr`,
   `$39.99–44.99 lifetime`), *not* the `$4.99` / `$39.99` shown on the paywall artboards.
   Applies in batch 10.
3. **Passport tab vs. "stamp/badge" language** — `CLAUDE.md` wants Passport visually
   distinct from a live world map, but artboard 11 uses a dimmed world-map watermark +
   `X / 195 countries` / `% of the world`. The handoff is the build target; noted so it
   is a conscious choice, not a slip.
4. **Processed hero images** — `uploads/8587a272…png` (logomark), `uploads/cb4892c4…png`
   (open/packed suitcase), `uploads/d5599fe2…png` (passport spread) exceed the design
   MCP's 256 KB read cap and could not be pulled in full. Raw look-alikes exist in
   `Diseño/Elements/`. Need full-res exports before the onboarding/tour screens (batch 4).
