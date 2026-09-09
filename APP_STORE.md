# App Store listing — Suite

Draft copy for App Store Connect. Fill the bracketed items before submitting.

---

## Basics

| Field | Value |
|---|---|
| **Name** (30 char max) | `Suite: Travel & Packing` |
| **Subtitle** (30 char max) | `Pack, map & log your trips` |
| **Primary category** | Travel |
| **Secondary category** | Productivity |
| **Bundle ID** | `com.suiteapp.Suite` |
| **Version** | `1.0.0` |
| **Age rating** | 4+ (no objectionable content) |
| **Price** | Free (with In-App Purchases) |

## Promotional text (170 char max — editable without review)

> Plan a trip, pack it without forgetting a thing, and watch it land on your
> world map and in your passport. Your whole travel history, in one place.

## Description (4000 char max)

**Suite is a calm home for every trip you take — the planning, the packing, and the memory of it afterwards.**

Three tabs, one loop:

**MAP**
A dark, hand-styled world map that fills in as you travel. Tap any country to mark it visited or add it to your want-to-go list, drill into its cities and regions, and see how much of the world you've covered.

**SUITCASE**
A packing checklist per trip that starts itself. Pick where and when you're going and Suite lays out a list from the trip type and the forecast — you just tick things off. One list per trip, so nothing gets left on the bed.

**PASSPORT**
Your travel stats, stamp-book style: countries and cities visited, continents, percentage of the world, and a log of every past trip.

Everything is stored on your device by default. Sign in is Apple only — no accounts, no email lists.

**Suite Pro** unlocks:
• Unlimited active trips and your full archive
• Reusable packing templates
• Smart packing suggestions and advanced weather
• iCloud sync and travel companions
• Export any packing list as a PDF
• The full places-been passport stats

Pro is $3.99/month, $24.99/year (5-day free trial), or $42.99 once for lifetime.

Questions or ideas: [support email]

## Keywords (100 char max, comma-separated, no spaces)

`travel,packing,checklist,trip,planner,list,suitcase,countries,map,been,passport,vacation,journey`

## What's New — v1.0.0

> First release. Map, Suitcase and Passport — plus Suite Pro for unlimited trips,
> templates, sync, PDF export and full passport stats.

## URLs

| Field | Value |
|---|---|
| Support URL | [https://…] |
| Marketing URL | [https://…] |
| Privacy Policy URL | [https://…] — **required** before submission |

## App Privacy ("nutrition label")

Data the app itself collects: **none leaves the device** unless the user turns on
iCloud sync (Pro), which uses the user's private CloudKit database.

- **Sign in with Apple**: the app stores the Apple user identifier and, on first
  sign-in, the display name — used only to identify the user's own data. Not linked
  to advertising, not used for tracking.
- **Trip / packing / visited-place data**: stored locally; synced to the user's
  private iCloud when Pro sync is on. Not accessible to the developer.
- **Weather**: destination name and dates are sent to Open-Meteo to fetch a
  forecast. No user identifier is sent.
- **Analytics / tracking**: none. No third-party SDKs.

Suggested answers: *Data Not Collected* for everything except "Contact Info →
Name" and "Identifiers → User ID" (Sign in with Apple), marked **not** used for
tracking and **not** linked to identity for advertising.

## In-App Purchases (App Store Connect)

| Product ID | Type | Reference name | Price |
|---|---|---|---|
| `com.suiteapp.Suite.pro.monthly` | Auto-renewable subscription | Pro Monthly | $3.99 / mo |
| `com.suiteapp.Suite.pro.yearly` | Auto-renewable subscription | Pro Yearly | $24.99 / yr, 5-day free trial |
| `com.suiteapp.Suite.pro.lifetime` | Non-consumable | Pro Lifetime | $42.99 |

Subscription group: **Suite Pro**. Mirror `Suite/Suite.storekit` exactly.

## Screenshots needed (per device size: 6.7", 6.5", 5.5" + iPad if shipping iPad)

1. Map tab — world with visited countries filled
2. Country sheet — Visited / Want to go + cities
3. Suitcase tab — a trip with its packing progress
4. Packing checklist — mid-pack
5. Passport tab — stats + continents
6. Paywall — the three plans
7. (optional) Reward moment — "That's your 8th country."

## Pre-submission checklist

- [ ] `DEVELOPMENT_TEAM` set in the Xcode project (needs the paid account)
- [ ] App icon 1024² with no alpha — **done** (`AppIcon.appiconset`)
- [ ] `ITSAppUsesNonExemptEncryption = false` in Info.plist — **done**
- [ ] Version `1.0.0`, build `1` — **done**
- [ ] Privacy Policy URL live
- [ ] The 3 IAPs created in App Store Connect and "Ready to Submit"
- [ ] Sign in with Apple tested on a real device
- [ ] Screenshots uploaded for every required size
- [ ] TestFlight build uploaded and internally tested
