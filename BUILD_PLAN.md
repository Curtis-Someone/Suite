# Suite — Build Plan

This is the execution order. Read this and `CLAUDE.md` in full before writing any code — `CLAUDE.md` is the rulebook (scope, design fidelity, working rules), this file is the sequence.

---

## Start here

1. Read `CLAUDE.md` in full.
2. Read this file in full.
3. Confirm the Claude Design handoff bundle is actually present and readable in this project. If it isn't, stop and ask — don't start building screens from memory of a description.
4. Confirm whether an Xcode project already exists in this folder or needs to be created from scratch. Don't assume either way.
5. Work through the batches below **in order**. Each batch has a "done when" checklist — build it, verify it against that checklist, then **stop and wait for review** before starting the next batch. Don't chain multiple batches into one pass.
6. Anything a batch needs that isn't covered by the design bundle, `CLAUDE.md`, or this file — stop and ask rather than deciding.

---

## Batch 1 — Foundation & Design Tokens

No screens yet. This batch makes every later batch possible.

- Create the SwiftUI App project (or confirm the existing one), matching the folder structure in `CLAUDE.md` (`Map/`, `Suitcase/`, `Passport/`, `Onboarding/`, `Shared/`, `Models/`, `Services/`).
- Pull colors, type scale, spacing scale, and corner radii from the design handoff bundle into a `DESIGN_SYSTEM.md` (or a `Theme.swift` constants file, whichever fits SwiftUI better — flag which you pick and why).
- Import Lucide icons into the asset catalog.

**Done when:** the app builds and runs a blank shell using the correct base color and no other screens.

---

## Batch 2 — Shared Component Library

- Build the reusable pieces every screen will need: primary pill CTA, card, progress bar, circular gauge, chip/toggle pill, bottom nav bar, section header, stat block.
- Each one built directly against the design bundle's version of that component — not approximated.

**Done when:** a single internal preview screen shows every component at every state (default, selected/active, disabled) and it visually matches the design bundle.

---

## Batch 3 — Data Models & Local Storage

- Core models: `Trip`, `Suitcase`, `PackingItem` (+ category), `Place`/`Country` (visited), `Template`, `UserProfile`/onboarding state, `Traveler` (model only — no sync logic yet).
- Local persistence layer (check current Apple docs for SwiftData vs. Core Data before choosing — this is new-tech territory per `CLAUDE.md` rule 4, flag the choice).

**Done when:** a sample `Trip` with a `Suitcase` and a few `PackingItem`s can be created, saved, and fetched back — no UI required for this batch.

---

## Batch 4 — Auth & Onboarding Flow

- Splash → three-card onboarding tour (one card per tab) → Welcome → Sign up / Log in → "Where are you from?" → optional setup-loading screen → main app shell (tab bar, three empty tabs).
- Home-country selection must actually seed Passport state (per the non-zero-progress rule) — this is the first place that rule gets implemented, not just described.

**Done when:** the full flow is navigable start to finish, and picking a home country visibly seeds passport data (not just accepted and discarded).

---

## Batch 5 — Suitcase Tab (core loop)

- Suitcase list (empty + populated states, readiness progress bar per card).
- New Suitcase creation flow (chip-grid multi-select: Accommodation, Transportation, Activities/Items, Other).
- Suitcase detail / packing checklist (collapsible categories, checked/total counters, readiness formula: baseline % on creation, fills as items are checked).
- Trip complete / archived state, past trips sub-view, trip detail.
- Weather integration (Open-Meteo) feeding basic conditions (Free) / smart suggestions (Pro-gated later — build the plumbing now, gate it in Batch 10).

**Done when:** a trip can be created, packed, checked off, and marked complete, with the progress bar moving correctly and never showing 0% right after creation.

---

## Batch 6 — Passport Tab

- Passport main (stat block, "world explored" bar — seeded, never 0%).
- Country detail, continent detail, full country list.
- Add-a-visited-place flow.

**Done when:** adding a place updates every relevant stat (country count, world %) immediately and correctly.

---

## Batch 7 — Map Tab

- World map showing visited places.
- Map view toggle, add-place-from-map.

**Done when:** the map renders, visited places are marked correctly, and adding a place here updates Passport too (single source of truth, not two separate lists).

---

## Batch 8 — Global & Shared Screens

- Profile, Settings, Search, Share card, Error state, permission soft-ask screens (location, notifications, etc.).

**Done when:** every screen here is reachable from its real entry point in the app (not just previewable in isolation) and matches the design system.

---

## Batch 9 — Reward Moments & Progress Polish

- The four reward overlay variants: suitcase packed, trip complete, new country added, milestone crossed.
- Wire each trigger into the real flow it belongs to (e.g. suitcase-packed fires when the last item is checked, not on a manual test button).

**Done when:** each overlay fires at the correct real moment, shows the real value (not placeholder text), and auto-dismisses correctly.

---

## Batch 10 — Monetization: Free / Pro + StoreKit

**Do not start this batch until the two open questions in `CLAUDE.md` are resolved with Ivan** (travelers/sync pairing, exact paywall trigger points).

- Tier-gating logic: trip cap, archive limit, suitcase-per-trip cap, template lock, weather tier, solo-only restriction, export lock.
- Paywall screen(s), StoreKit products (monthly/annual/lifetime), purchase + restore flow.

**Done when:** free-tier limits are enforced at the correct trigger points, and a sandbox purchase unlocks Pro features immediately.

---

## Batch 11 — Pro Feature Layer: Sync, Collaborators, Export

Depends on Batch 10 (needs entitlement checks in place).

- iCloud sync wiring.
- Traveler/collaborator invite flow (built on top of the `Traveler` model from Batch 3).
- PDF export, Messages/text share.

**Done when:** data syncs correctly across two simulated devices/accounts, and an exported PDF matches the suitcase it was generated from.

---

## Batch 12 — Polish, QA & App Store Prep

- Full empty/loading/error state pass across every screen.
- Accessibility pass (Dynamic Type, VoiceOver labels, contrast).
- App Store assets: icon, screenshots, listing copy.
- Full StoreKit sandbox test pass, TestFlight build.

**Done when:** the app is ready to submit for App Store review.
