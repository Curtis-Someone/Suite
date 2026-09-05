# Suite

**Your trip, packed — and remembered.**

Suite is an iOS app built around a simple metaphor: your packing list *is* a digital suitcase. It's grown from a focused packing tool into a lightweight travel companion — helping you pack smarter for the trip ahead, and keeping a record of everywhere you've been.

---

## What Suite Does

Suite is organized around three core tabs:

- **🗺️ Map** — a world map of the places you've visited, built from your trip history. Not a live trip-planning or navigation tool — it's a visual record of your travel footprint.
- **🧳 Suitcase** — the packing checklist for your current or upcoming trip. Each trip gets its own suitcase: a self-contained list tied to that trip's dates, destination, and conditions.
- **🛂 Passport** — your travel stats and history at a glance: countries and cities visited, trips completed, milestones reached — styled like passport stamps and badges rather than dashboards and charts.

Suite is deliberately **not** a trip-planning super-app. It doesn't touch flight tracking, hotel or accommodation booking, travel document storage, or itinerary building. It does travel *memory and packing* — and aims to do that well.

## The Core Loop

1. **Plan a trip** — set up basic trip context: destination, dates.
2. **Pack it** — build the packing list inside that trip's suitcase, informed by real weather data for the destination.
3. **Track it** — completing a trip adds it to your passport: a new stamp, an updated country count, a growing sense of where you've been.
4. **Reuse what worked** *(Pro)* — save a packed trip as a template so the next similar trip starts from something proven, not a blank page.

Progress is never shown as empty or zero — a home country seeds your passport from first launch, and a freshly created suitcase starts with a baseline readiness score rather than a bare 0%.

## Key Features

- **Trip-based packing** — every trip gets its own suitcase rather than one generic master list
- **Weather-aware packing** — live weather via the [Open-Meteo](https://open-meteo.com/) API grounds packing decisions in real forecast data
- **Places-been tracking** — a passport-stamp/badge style record of countries and cities visited, built from completed trips
- **Templates** *(Pro)* — save a packed suitcase and reuse it for future trips
- **Multi-device sync** *(Pro)* — iCloud sync keeps trips and suitcases current across devices
- **Collaborators** *(Pro)* — add travelers to a shared trip
- **Export & sharing** *(Pro)* — PDF and Messages export of a packing list

## Free vs. Pro

| | Free | Pro |
|---|---|---|
| Active trips | 2 at once | Unlimited |
| Trip archive | Last 3 trips | Full history |
| Suitcases per trip | 1 | Unlimited |
| Templates | — | ✓ |
| Weather | Basic conditions + forecast | Advanced forecast + smart packing suggestions |
| Travelers | Solo only | Collaborators |
| Sync | Local, single device | iCloud sync across devices |
| Export / sharing | — | PDF + Messages |
| Passport stats | Basic | Full places-been tracking |

**Pricing:** $3.99/month · $24.99/year (default) · $39.99–$44.99 lifetime, with a 5–7 day free trial on annual plans.

## Design

Suite's visual identity leans into a premium, considered feel rather than a generic utility-app look:

- **Near-black base** (`#0A0A0A`) with a single **amber accent** (`#D09A42`)
- Consistent **Lucide** iconography (MIT-licensed) for uniform stroke weight throughout
- Reward moments (a packed suitcase, a completed trip, a new country) surface as a brief overlay rather than a page navigation
- Numbers are monospaced, words are not — a deliberate typographic split between data and copy

## Technical Foundation

- **Platform:** iOS, built in SwiftUI
- **Storage:** Local-first, with iCloud sync for Pro users
- **External data:** Open-Meteo API for weather
- **Monetization:** StoreKit (in-app purchases / subscriptions)
- **Icons:** Lucide icon library

## Status

Suite is an active portfolio project, developed end-to-end with Claude generating the codebase via Claude Code. It's currently moving from design and product spec into build.

---

*This README reflects Suite's current product direction and is updated as the app evolves.*
