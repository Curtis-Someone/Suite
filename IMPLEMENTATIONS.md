# Suite — Implementation Plan (reconciled against the current build)

Everything decided across the design review, turned into discrete batches.

**This file has been reconciled** against the code that already exists in this repo
(onboarding, all three tabs, global screens — roughly 50 Swift files, built over the
`BUILD_PLAN.md` batches 1–8, currently uncommitted on top of the scaffold commit). The
original version of this doc was written as if starting from an empty project and
contradicted several decisions already made and resolved with Ivan. Each batch below now
carries a **Status** line and the prompt text is adapted so it can be pasted into Claude
Code without re-introducing deleted work or undoing signed-off design choices.

Guiding rule for this pass (Ivan's call): **the existing build and previously-resolved
decisions win. Apply only the non-conflicting deltas from the design review.**

---

## Research recap

Before the review, I looked into how this category of app actually gets designed and
shipped right now. This is unchanged — it's what the recommendations are grounded in:

- **Apple's iOS 26 "Liquid Glass" system.** Glass is "the navigation layer that floats
  above the content" — tab bars, toolbars, sheets, floating actions. Recompiling with
  Xcode 26 auto-applies it to *standard* system controls; custom bars don't get it free.
- **Onboarding research.** Most apps lose the majority of daily users within 3 days.
  Loading screens and extra pre-signup steps are worth testing, not assuming — one
  education app saw a 22% conversion lift from removing a loading screen. Minimum friction
  to first value; personalize early; defer non-essentials.
- **Paywall/subscription research** (RevenueCat, Adapty, Airbridge). Anchor the annual
  plan and show its monthly-equivalent price. A lifetime tier disproportionately converts
  high-intent users at onboarding even when few pick it — it's an anchor. Gate at the
  moment of friction. Cap visible plan choices at 2–3.
- **Packing-app landscape.** PackPoint (weather suggestions), Packr (family sharing),
  Packing Pro (weight tracking) are the established players. A rules-table approach is the
  proven, safer v1 pattern; on-device AI is a later fit given the no-backend constraint.
- **Contrast/accessibility.** Brand amber (`#D09A42`) on the light backgrounds is roughly
  2.5:1 — short of the 3:1 minimum for even large text. A real issue to design around.
- **Countries-visited survey data** (Pew, Agoda/YouGov, the Visited app). General-
  population median is roughly *one* country ever. Self-selected travel-app users average
  ~15–18, right-skewed. Global rank must be calibrated against travel-app users.
- **MapKit/GeoJSON.** `MKGeoJSONDecoder` + MapKit overlays is Apple's built-in path.
  **Note:** the design review recommended this, but the Map tab in this repo was already
  built three times and MapKit was explicitly rejected by Ivan as off-brand — see Batch 3.

---

## How to use this doc

Nine batches. Each has a one-line "why", a **Status** against the current build, and a
prompt to paste into Claude Code.

- The docs a batch may reference live in `Suite/Documentos/`: `Pro Features.md`,
  `Suite - Product Overview.md`, `Suite app design.pdf`, plus `SuiteEntitlements.swift`
  (Ivan's Free/Pro enforcement layer to port when Batch 6 runs) and
  `suite-design-compendium.md`. The primary design handoff is the Claude Design
  `.dc.html` files (`Suite Screens Light.dc.html` is the definitive one); tokens are
  extracted in `DESIGN_SYSTEM.md` + `Suite/Shared/Theme/`.
- **Blocked batches:** Batch 6 (Pro/Paywall) still needs Ivan's call on whether
  collaborators and iCloud sync are bundled as one Pro unit — see `CLAUDE.md` open
  questions. Batch 8 item 1 needs the reward-overlay screens (R1–R3) built first; they
  don't exist yet.

Start order: **Batch 1** (foundation deltas) → 2 → 3 and 4 → 5 → 7 → 6 (when unblocked)
→ 8 last. Batch 9 is already done.

---

## Batch 1 — Visual foundation deltas

**Why:** the token and nav system is already the thing every screen inherits — so this
batch is now *targeted fixes to it*, not a rebuild.

**Status:** the foundation is built. `Theme.Palette` + `Font.Suite` in
`Suite/Shared/Theme/`, custom `BottomNavBar`, `RootView` → `OnboardingFlow` /
`MainAppShell`. Three real deltas remain; three items from the original plan are
**dropped as conflicts** (see notes).

```
Make three targeted changes to Suite's existing theme system in
Suite/Shared/Theme/. Do NOT restructure the token system — it stays as
Theme.Palette / Font.Suite Swift constants, which DESIGN_SYSTEM.md names as the
canonical form.

1. Text-safe amber. Add one new token to Theme.Palette — a darker, slightly more
   saturated amber for use as small/mid-size TEXT on the light backgrounds. Brand
   amber #D09A42 is ~2.5:1 on ground/surface, below WCAG for text. Target roughly
   #A9762B / tune to clear 4.5:1 on #FFFFFF and #F5F3EF. Name it e.g.
   `accentText`. Keep `accent` (#D09A42) for fills, icon color, and large display
   numerals only. Do not touch `accentHigh` (that's the lighter hover value).
   This new token is what Batch 8's contrast audit will switch text instances to.

2. Dark values. Theme.Palette currently defines flat light-only values. Convert
   every token to Color(light:dark:) (the helper already exists in Color+Hex.swift)
   so a dark appearance is defined from day one. Dark can initially mirror or be a
   simple near-black inversion of light — real dark calibration is a fast-follow,
   not this batch. DESIGN_SYSTEM.md section 1 has a light+dark table to seed from.
   Keep the auth hero at a fixed #0A0A0A in both modes.

3. Accessibility rule (already partly followed — make it explicit in
   DESIGN_SYSTEM.md): anywhere color alone signals state (visited vs not-visited,
   ready vs not), pair it with a non-color cue — label, checkmark, or icon. Add a
   short "Accessibility rules" section to DESIGN_SYSTEM.md so later batches follow
   it deliberately.

DROPPED from the original plan (conflicts with resolved decisions — do not do):
- "Define colors as Xcode Color Set assets (.xcassets)." The build uses Swift
  tokens; that's canonical per DESIGN_SYSTEM.md. Keep Swift tokens.
- "Numbers are always monospaced, as a global rule." The handoff resolved this
  the other way: big hero stat numbers are Archivo (proportional); only small
  inline data (Font.Suite.data / .label / .labelS / .micro) is JetBrains Mono.
  Typography.swift already reflects this. Leave it.
- "Rebuild the tab bar with native TabView for Liquid Glass." BottomNavBar is a
  deliberate custom view (hand-drawn Path glyphs, filled-amber active state) —
  DESIGN_SYSTEM.md section 7 flags it as an intentional exception. Keep it.
  Sheets and menus in the app already use native .sheet / Menu, which do pick up
  system materials — no change needed there.
```

---

## Batch 2 — Onboarding & auth deltas

**Why:** onboarding-length research says every pre-value screen is a drop-off risk; one
tour affordance is missing.

**Status:** the flow is built in `Suite/Onboarding/` (`OnboardingFlow` router: splash →
tour → welcome → auth → homeCountry → settingUp → app). **Auth is Sign in with Apple
only, or Skip** — resolved with Ivan; there is no email/password, no Google, no
signup/forgot-password screens, and that layer was built once and fully deleted. One real
delta remains.

```
Make one change to the existing onboarding flow in Suite/Onboarding/:

1. Add a visible "Skip" affordance to the 3-screen marketing tour
   (OnboardingTourView) — a text button, top-trailing, that calls onDone() to
   jump straight to Welcome. Keep the existing pagination dots and per-screen CTA.

ALREADY DONE — no action:
- The "Setting up your trip world…" loading screen (SettingUpView) already sits
  immediately after "Where are you from?" (HomeCountryView), right before the app.
- The tour's demo stats (10 / 195 countries, 5% of the world) are already shown
  unlabeled, no "illustrative" tag. Leave them.

DROPPED from the original plan (conflicts with the resolved Apple-only auth
decision — do not build): password strength meter, show/hide password toggle,
forgot-password / check-inbox recovery loop, Google sign-in, any email/password
signup screen. Screens 08 / A1 / A2 stay intentionally absent.

Not in this batch: the location/notification permission-priming screens
(PermissionView, A3/A4) already exist and are reached from the Map locate button
and Settings — leave their placement as-is.
```

---

## Batch 3 — Map tab deltas

**Why:** the map is built and iterated; only small mockup-cleanup items remain.

**Status:** built in `Suite/Map/` as a **custom vector `Canvas`** (`WorldMapView`, Web
Mercator, bundled Natural Earth 50m `world.min.json` → `Path`s), plus a post-B8 country
**bottom sheet** with Cities/Regions tabs. MapKit was built as a prior version and
**explicitly rejected by Ivan as off-brand** — do not reintroduce it. One real delta;
the rest is blocked on Pro gating.

```
Make one change to the existing Map tab in Suite/Map/:

1. MapTabView bottom-left control: make it icon-only. It currently renders a
   Lucide icon plus the mode label ("Countries") in a frosted capsule — drop the
   Text, keep the icon, keep the frosted capsule and the tap target that opens
   MapViewToggleSheet (M3). Size it as a circular icon button consistent with the
   top-right locate button.

ALREADY DONE / ALIGNED — no action:
- The "+" FAB is already the single distinct add-a-visit action (opens the shared
  AddVisitView). It and the toggle control do not overlap.
- Boundaries are already bundled and rendered fully offline from local GeoJSON —
  just not via MapKit. Do NOT switch WorldMapView to MKGeoJSONDecoder / MapKit
  overlays; the custom Canvas render is the signed-off approach.

DEFERRED to Batch 6 (needs the Pro gating layer):
- Free = country-level tracking only; Pro adds city and region-level tracking,
  with a region-lock screen (PRO3, "Tuscany"). Right now the Cities/Regions map
  modes show "Soon" and the country sheet lets anyone toggle city-level visits —
  wiring the Free/Pro boundary here happens when Batch 6 lands the entitlement
  layer, not before.
```

---

## Batch 4 — Suitcase creation & packing deltas

**Why:** the core loop and strongest-designed part of the mockups; changes are
consistency (gating, native patterns) plus one genuinely new estimate feature.

**Status:** built in `Suite/Suitcase/` (`NewSuitcaseFlow`, `PackingChecklistView` covering
both S3 live and S4 completed, `PackingPreset` static rules). Four deltas; one blocked;
one new.

```
Make these changes to the existing Suitcase flow in Suite/Suitcase/:

1. "+ Travellers" button (NewSuitcaseFlow, S2B): un-gate it. It's currently
   dimmed (.opacity(0.5)) and inert. Make it functional for LOCAL traveller
   names only — add/remove names attached to the trip, no invite, no sync, no Pro
   lock badge. Use the existing Traveler model.

2. "Save as template" (PackingChecklistView header menu, S4): it's currently
   .disabled(true). Replace that with an enabled row that carries a Pro lock
   badge and routes to the Suite Pro pricing screen (Batch 6). Until that screen
   exists, route to a placeholder / no-op and leave a TODO — do not build inline
   template-saving on Free.

3. Checklist item deletion (PackingChecklistView row, S3): remove the persistent
   trailing "×" button (SuiteIconView(icon: .close ...)) that sits on every
   unchecked row. Replace it with native .swipeActions(edge: .trailing) →
   destructive Delete on the row. Match Mail / Reminders behaviour.

4. Packing suggestions stay on the existing PackingPreset rules/catalog approach
   (accommodation + transport + activity tags → category checklists). Do NOT
   build on-device AI generation — explicitly deferred. (No code change; noting
   it so it isn't "improved".)

5. Weight tracking (NEW — no artboard exists for this, keep it minimal): add a
   static per-category / per-item weight lookup (e.g. "linen shirt ~150g",
   "walking shoes ~800g"), summed into a running total shown on the checklist
   header against a configurable limit. Estimate only, no hardware. If this needs
   anything beyond a lookup table + sum + a header readout, STOP and flag it
   rather than building more.

BLOCKED on Batch 6 (needs the entitlement layer):
- Paywall trigger points: the 1-suitcase-per-trip cap is the primary inline
  upsell (interrupt when adding a 2nd suitcase); the 2-active-trips cap redirects
  to the dedicated pricing screen instead. Wire these when Batch 6 lands.
```

---

## Batch 5 — Passport & Global rank

**Why:** survey research shapes how Global rank must be calibrated to stay meaningful and
honest.

**Status:** the Passport tab is built in `Suite/Passport/` (`PassportTabView`,
`ContinentDetailView`, `CountryListView`, `TripsListView`) as designed — P2 Trip detail
deliberately skipped (no photos in the app). Global rank and the story share card are
new.

```
Two additions. The Passport tab itself (screen 11, P1/P3/P4) is already built as
designed — no changes to it.

1. Global rank (NEW Pro feature — build the calc + display now; the Pro lock
   itself lands with Batch 6):
   - Client-side estimate only. Suite has no backend and never compares real
     users. Keep it that way.
   - Show ONLY the user's own estimated percentile ("You're in roughly the top
     X% of estimated travelers"). Do NOT render fabricated named "neighbor"
     entries (the PRO1-4 mockup's "#412 A. Rossi / #413 You / #414 M. Lund") —
     they read as fake social proof. Own number only.
   - Calibrate against a self-selected travel-app-user distribution: ~15–18
     countries average, right-skewed, long tail to 40–50+ at the top few percent.
     Not general world-population data (median ~1, which trivially top-percentiles
     everyone). Implement as a small bucketed lookup table, a handful of
     breakpoints — no aggregate data collection.

2. Passport share card 9:16 variant (NEW): ShareCardView (G4) currently renders
   only the static square card. Add a 9:16 story-format variant sized for
   Instagram / TikTok, reusing the existing stat + visual system. Offer both
   formats from the same share entry point.
```

---

## Batch 6 — Pro / Paywall

**Why:** paywall research says a lifetime tier anchors even when rarely chosen; the
mockup's pricing is superseded.

**Status:** **not built, and partly blocked.** No Pro screens exist (Pro1–Pro1-5, Pro2,
Pro3). Before starting, Ivan must confirm the one open `CLAUDE.md` question:
**collaborators + iCloud sync bundled as a single Pro unit?** (The other open question —
exact paywall trigger points — is now answered by Batch 4's item list: 1-suitcase cap
inline, 2-trip cap → pricing screen.) When unblocked, port
`Suite/Documentos/SuiteEntitlements.swift` into `Suite/Services/` as the enforcement
layer.

```
Build the Pro benefits carousel (PRO1 through PRO1-5) and paywall (PRO2) per
Suite app design.pdf. Use "Pro Features.md" as the canonical source for pricing
and feature copy — IGNORE the numbers on the PRO2 artboard ($4.99/yr, $39.99,
no lifetime). Those are superseded and this was already resolved.

Pricing to show:
- Monthly: $3.99/mo
- Yearly: $24.99/yr — the anchored default, kept visually favored. Recalculate
  the "SAVE X%" badge and per-week equivalent against these corrected numbers.
- Lifetime: $39.99–$44.99 — behind a "See all plans" tap, not a third card on
  the primary screen. Don't drop it.
- Trial: 5–7 days free, annual plan only.

Then wire the entitlement layer (ported from SuiteEntitlements.swift) into the
gates the earlier batches left as TODOs:
- Suitcase: 2nd-suitcase-per-trip = inline interrupt; 2nd-active-trip = redirect
  to this pricing screen; "Use as template" Pro badge → this screen.
- Map: city + region-level tracking becomes Pro; Cities/Regions modes and the
  region-lock screen (PRO3, "Tuscany") gate here.
- Passport: Global rank becomes a Pro-gated view.

Update the Global rank benefit screen (PRO1-4) to match Batch 5 — illustrative
own-percentile only, no named comparison users.

The rest of the carousel (cities & regions, unlimited suitcases, templates,
iCloud sync) matches Pro Features.md already.
```

---

## Batch 7 — New screens for v1 (templates, notifications)

**Why:** both are named as headline Pro benefits with on-screen CTAs, but there's no
screen to land on.

**Status:** neither exists. Non-conflicting. The template screen intersects the existing
`Template` model and Batch 6's Pro gating.

```
Build two screens that don't exist yet, both confirmed for v1:

1. Template management screen — a list of the user's saved packing templates,
   each with rename and delete, and a "start a new suitcase from this template"
   entry point. Reachable from wherever "Save as template" / "Use as template"
   point, and as a new path inside NewSuitcaseFlow (S2A) alongside "start from
   scratch". Uses the existing Template / TemplateItem models. Templates are Pro
   — respect the entitlement layer once Batch 6 lands it.

2. In-app notification / reminder center — past and upcoming reminders (the
   "nudge two days before each trip" mechanic that PermissionView / A4 sells).
   Reachable from Settings. Reflects what's actually scheduled, not a static
   mockup.

Do NOT build here: a dedicated weather-forecast detail screen (keep the single
inline chip on the suitcase header), or collaborator management UI (the
"+ Travellers" button stays local-names-only). Both deferred to a later version.
```

---

## Batch 8 — Accessibility & polish pass

**Why:** small cheap fixes individually, real issues if shipped as-is.

**Status:** run this LAST. Item 1 is **blocked** — the reward-overlay screens (R1–R3) it
targets don't exist yet and must be built first (they were the `BUILD_PLAN.md` Batch 9
that was never reached). Items 2–3 are ready once Batch 1's `accentText` token exists.

```
Accessibility pass across the built screens:

1. (BLOCKED until reward overlays R1–R3 exist — build those first.) Reward
   overlays ("All packed for Lisbon", "Trip complete", "That's your 8th
   country"): don't force the 2–3s auto-dismiss when VoiceOver is running —
   disable it or extend well past announcement time. Tie the dismiss duration to
   Reduce Motion generally. Keep tap-to-dismiss.

2. Amber contrast: audit every place brand amber #D09A42 is used as TEXT at
   small/medium size on light backgrounds. Switch those to the `accentText`
   token from Batch 1. Leave brand amber where it's a fill behind dark text, an
   icon color, or a large display numeral (the big "10" in "10 / 195").

3. Color-as-only-signal audit: every screen where color indicates
   visited/not-visited or similar (world map, country lists, filter chips,
   checklist rows) — confirm a non-color cue is also present (label, checkmark,
   icon). Add one where missing.
```

---

## Batch 9 — Docs & continuity (already done)

**Status:** done. `Pro Features.md` and `Suite - Product Overview.md` in
`Suite/Documentos/` are the canonical product docs. No further edits unless a future
decision changes something.

---

## Suggested sequencing

1 → 2 → 3 and 4 (both depend only on 1) → 5 → 7 → 6 (once Ivan confirms the
collaborators+sync bundling) → 8 last (needs reward overlays built + Batch 1's
`accentText`).
