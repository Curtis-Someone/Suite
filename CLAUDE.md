# Suite — CLAUDE.md

Read this in full before writing any code in this repo. It defines scope, design fidelity, and working rules for building Suite.

---

## What Suite is

Suite is an iOS travel companion app built in SwiftUI, structured around three bottom-nav tabs:

- **Map** — world map of places visited
- **Suitcase** — packing checklist per trip
- **Passport** — travel stats and history

33 screens total, spanning auth, onboarding, and all three tabs. Core loop: plan a trip → pack it in the Suitcase → the trip lands on the Map and in the Passport once it's done.

**Explicitly excluded:** flight tracking/booking, hotel/accommodation booking, travel document storage, itinerary building. These were dropped from the original MVP scope.

**Note on Map:** an earlier version of this product excluded maps entirely. That exclusion no longer applies — Map is one of the three core tabs in this version. Don't reintroduce the old "no maps" constraint.

**Passport "places-been" stats** use a stamp/badge aesthetic — countries/cities visited, presented like passport stamps. This is deliberately distinct from the Map tab's live world map. Don't conflate the two or build one as a reskin of the other.

---

## Design fidelity — do this before building any screen

The real screens exist in a Claude Design project and were handed off directly into this environment. Before writing UI code for a given screen:

1. Find the handed-off design content for that screen in this session/repo.
2. Pull exact values from it — hex colors, font sizes/weights, spacing, corner radii, component structure. Do not eyeball or approximate from memory of a description.
3. If it's useful, extract a running `DESIGN_SYSTEM.md` (colors, type scale, spacing scale, component patterns: cards, pills, progress bars, nav bar) as you go, so later screens stay consistent with earlier ones.
4. Known reference points from prior design work — verify these against the actual handoff, which wins if anything conflicts:
   - Base: near-black `#0A0A0A`
   - Single accent: amber `#D09A42`
   - Numbers are always monospaced, words never are
   - Icons: Lucide, one consistent stroke weight throughout
5. If the handoff is missing something a screen needs (a state, a value, a spacing you can't find), stop and ask. Don't invent it.

---

## Free / Pro tiers

**Free:** 2 active trips, last 3 archived trips, 1 suitcase per trip, no templates, basic weather only, solo trips only, local storage, no export.

**Pro:** unlimited active trips and suitcases, full archive, templates, advanced weather + smart packing suggestions, collaborators, iCloud sync, PDF/Messages export, Passport places-been stats.

**Pricing:** $3.99/mo, $24.99/yr (anchored default), $39.99–$44.99 lifetime (trust signal, not a revenue driver). 5–7 day free trial, annual plan only.

### Unresolved — confirm with Ivan before building these specific parts

- **Travelers + sync:** collaborators are bundled under Pro together with iCloud sync, since adding a traveler is only meaningful once data syncs across people/devices. Confirm this pairing is intentional before building the invite/sync flow — don't build collaborator UI ahead of sync being wired up.
- **Paywall placement:** which limits trigger an inline upsell at the moment of friction vs. a dedicated pricing screen. The 1-suitcase cap is the likely sharpest moment; the 2-trip cap is softer. Confirm exact trigger points before wiring StoreKit prompts into the flow.

---

## Working rules

1. **Simplicity first.** Minimum code that solves the problem. No speculative abstractions, no config/flexibility that wasn't asked for, no error handling for scenarios that can't happen.
2. **File naming.** One primary type per file, filename matches it exactly (`TripCardView.swift`, `PackingItem.swift`, `WeatherService.swift`). Folders by feature (`Map/`, `Suitcase/`, `Passport/`, `Onboarding/`, `Shared/`), not by layer.
3. **No silent assumptions.** If a data model, edge case, or product behavior has more than one reasonable reading, stop and ask rather than picking one. Don't hide confusion — name what's unclear.
4. **New tech → check before building.** Before implementing something unfamiliar (StoreKit, iCloud/CloudKit sync, PDF export, etc.), check for an installed skill first. If none exists, check current Apple documentation before writing code, and flag to Ivan if something needs installing.
5. **Design fidelity.** Build to the handoff bundle exactly — see above. Flag anything the bundle doesn't specify instead of guessing.
6. **Surgical changes.** Touch only what a task requires. Don't refactor or "improve" adjacent code that isn't part of the current change.

---

## Tech stack

- iOS / SwiftUI
- Storage: local by default; iCloud sync (Pro only)
- Weather: Open-Meteo (free tier)
- Monetization: StoreKit (in-app purchases / subscriptions)
- Icons: Lucide (MIT-licensed)
- No backend infrastructure
