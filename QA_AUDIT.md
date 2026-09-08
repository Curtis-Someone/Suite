# Suite — QA Audit

**Date:** 2026-09-08
**Branch audited:** `batches-1-8-checkpoint` @ `f712d10`
**Method:** static code review of the full codebase (80 Swift files, all 11 SwiftData models,
all services, all shared components, asset catalog, Info.plist / entitlements / `.storekit`,
project settings) + a clean `xcodebuild` for the simulator. No device/simulator interaction
was possible from this environment, so anything marked *verify on device* is a code-level
finding that needs a visual/behavioural confirmation.

**Build:** `** BUILD SUCCEEDED **`, zero compiler warnings, before and after the two fixes below.

---

## 1. Executive summary

| | |
|---|---|
| Screens / states in inventory | 45 (see §4) — all reached a verdict |
| Findings total | 71 |
| 🔴 Blocking | 1 |
| 🟠 High | 10 |
| 🟡 Medium | 34 |
| 🟢 Low / cosmetic | 25 (grouped) |
| Fixes applied this pass | 2 (TripStatus date boundary; WeatherService array-bounds hardening) |
| Reported only | 69 |

**Shape of the results.** The component library, the token system, the SwiftData schema
(CloudKit-shaped, all defaulted) and the StoreKit 2 verification path are solid. The
problems cluster in five places:

1. **Advertised-but-unbuilt features.** The paywall and Pro-benefits carousel sell iCloud
   sync, collaborators/travellers, smart packing suggestions, advanced weather and
   city/region tracking. None are implemented. "Packing reminders", "Trip recaps",
   "Units" and the Map "fill in my location" button are shipped UI for features with no
   backing code.
2. **Dead controls / dead-ends.** Search results, "Delete account", the signed-out
   "Sign in" button, "+ Travellers", the Cities/Regions map toggle — all render as
   tappable and do nothing.
3. **Submission blockers.** No in-app account deletion (Guideline 5.1.1(v)); no functional
   Terms / Privacy links on the subscription paywall (Guideline 3.1.2); a location
   permission prompt with no feature behind it.
4. **Accessibility.** No Dynamic Type support anywhere; multiple custom controls
   (`SuiteSwitch`, `SegmentedToggle`, the date grid, the whole map) are invisible or
   inert to VoiceOver; selection state is colour-only in several places.
5. **Passport stat integrity.** The country catalog is `Locale.Region.isoRegions`
   (~250 entries incl. `EU`, `UN`, pseudo-codes) but the denominator is 195, so
   ">100% of the world" and non-country home picks are possible; un-toggling your home
   country wipes the onboarding seed and lets the Passport show `0 / 195`.

**Security / privacy is clean:** no hardcoded secrets anywhere; Open-Meteo calls are HTTPS
and carry only the destination name / lat-long / dates (no user id, no device location);
Sign in with Apple requests `.fullName` only and never `.email` (so the "Hide My Email"
relay concern doesn't apply); Pro entitlement is derived only from `.verified` StoreKit 2
transactions, never a naive local flag.

---

## 2. Severity table

Categories refer to §5 of the audit brief (A functional · B navigation · C visual · D UX/motion ·
E accessibility · F data · G security/privacy · H monetization · I offline · J localization ·
K performance · L edge/empty states).

### 🔴 Blocking

| # | Screen / flow | Repro | Expected | Actual | Cat | Status |
|---|---|---|---|---|---|---|
| B‑01 | Map country sheet (`CountryDetailView`) & Add‑visits sheet (`AddVisitView`) | Open the sheet for your **home country** (or any country auto‑stamped by completing a trip) → tap the **Visited** pill to turn it off | A confirmation; trip‑sourced stamps and the onboarding home seed are protected | `toggleVisited()` / `toggle()` run `for v in visits { context.delete(v) }` — **every** `VisitedPlace` for that code is deleted with no prompt, incl. `isHomeCountry` and `sourceTripID` records that are meant to be permanent. Passport then renders `In total 0 / 195 · 0%` + "Your passport is empty", violating the hard "no stat block ever shows 0 / home seeded from day one" rule. | F / A | **Reported** — fix is a product decision (protect the seed? confirm? make the pill un‑toggle only the country‑level row?) |

### 🟠 High

| # | Screen / flow | Repro | Expected | Actual | Cat | Status |
|---|---|---|---|---|---|---|
| H‑01 | Settings → Account → "Delete account" | Tap the row | Account + all local data (and any cloud copy) deleted | The row is a plain `HStack` with a chevron and `.contentShape` but **no Button / action** — nothing happens. There is no account‑deletion code anywhere. App Store **Guideline 5.1.1(v)** requires in‑app deletion for an app with Sign in with Apple. | A / G | Reported — needs a feature |
| H‑02 | Paywall (`PaywallView` line 108‑109) & Sign‑in (`AuthFormView` line 112) | Tap "Terms of Use" / "Privacy policy" | Opens the document | Both are plain `Text(...).underline()` — not links, nothing opens. No privacy policy exists in the app. Auto‑renewable subscriptions require functional EULA **and** Privacy Policy links in the binary (**Guideline 3.1.2**). | G / H | Reported |
| H‑03 | Search (`SearchView`, from the Suitcase top bar) | Search "japan", tap a result | Navigates to the trip / country / city | `row(_:)` returns a styled row **with a trailing chevron** but is not wrapped in a Button or `NavigationLink` — every result is a silent no‑op. | A | Reported (no destination is wired; needs design) |
| H‑04 | Profile (`ProfileView` line 81‑84) | Sign out, reopen Profile, tap the "Sign in" button | Presents Sign in with Apple | Action is `{ if auth.isSignedIn { auth.signOut(...) } }` — no `else`, so "Sign in" does nothing. There is **no re‑authentication path anywhere** after onboarding (the Settings "Apple ID" row is also a dead chevron row). | A | Reported |
| H‑05 | Map → top‑right location pin (`MapTabView` line 41, `PermissionView` line 52‑55) | Tap the pin, grant location | App fills in countries/cities as you travel (per the Info.plist string) | Completion closure is `{}`. `CLLocationManager()` is a throwaway local (the prompt often won't even present), there is no delegate and nothing consumes location. The `NSLocationWhenInUseUsageDescription` promises a feature that doesn't exist → permission‑purpose rejection risk. | A / G | Reported — recommend removing the button + Info.plist key for v1 |
| H‑06 | Settings → "Packing reminders" / "Trip recaps" | Enable, grant notifications | A reminder 2 days before each trip | The only `UNUserNotificationCenter` call in the codebase is the permission request. **Zero notification‑scheduling code.** Toggles persist a bool nothing reads; the user never gets a notification. | A / H | Reported |
| H‑07 | Paywall / ProBenefits carousel | Read the benefit copy | Features exist | Sells "iCloud sync", "travellers / shared trips", "Smart packing", "advanced weather", "track cities & regions". **None are implemented** — `SuiteApp` configures no CloudKit container, there is no suggestions engine, weather is basic‑only. | H | Reported (sync/collab documented as deferred in project notes; the paywall copy was not gated to match) |
| H‑08 | New Suitcase flow / monetization | Try to add a second bag to a trip | Inline upsell (`UpsellMoment.secondSuitcase`) — the spec's sharpest conversion moment | There is **no "add another suitcase" UI**, so `PackingGate.canAddSuitcase` / `.secondSuitcase` have no call site. The "1 suitcase per trip" Free limit is neither enforced nor monetised. | H | Reported |
| H‑09 | `Trip.status` (all trip lists, card styling, gating) | Have a trip whose last day is today, or a single‑day trip today | `.active` all of the first and last calendar day | *(before fix)* `endDate` is stored at `startOfDay`, and `now > endDate` → the trip flips to `.past` at 00:00 on its final day (a single‑day trip is `.past` for its whole day): dropped from "Upcoming", card greyed / "Done" badge mid‑trip, and a Free trip slot frees up a day early. | F | **✅ FIXED** — `Trip.swift`, now compared at `Calendar.startOfDay` day granularity |
| H‑10 | `AddVisitView` / `CountryDetailView` un‑visit (non‑home case) | Turn "Visited" off for a country you visited on two trips + one manual add | Reversible, scoped, confirmed | Deletes all `VisitedPlace` rows for the code incl. city‑level records and trip stamps — no confirm, no undo. Same root as B‑01. | F / A | Reported |
| H‑11 | `WeatherService.forecast` | Open‑Meteo returns a ragged response (fewer `weathercode` than `time` entries) | No crash | *(before fix)* `daily.time.indices.map { daily.weathercode[i] }` force‑indexed parallel arrays → out‑of‑range crash. (Not reproducible with the current API, which returns lockstep arrays — hardening.) | K / F | **✅ FIXED** — clamps to the shortest array |

### 🟡 Medium

| # | Screen / flow | Issue | Cat |
|---|---|---|---|
| M‑01 | Whole app | **No Dynamic Type support.** Every string uses `Font.archivo(fixedSize)` / `Font.Suite.*` — fixed points, no `relativeTo:` / `UIFontMetrics`. Layout is built on fixed heights (44–72 pt rows, `presentationDetents([.height(430)])`, non‑scrolling paywall). Large accessibility text sizes will clip / overlap. | E |
| M‑02 | `SuiteSwitch` (Settings toggles) | `.onTapGesture` on a `ZStack` — no `Toggle`/Button, so **no `.isToggle` trait, no on/off value, no "double‑tap to toggle" hint** to VoiceOver, no Switch Control / Full‑Keyboard support. | E |
| M‑03 | `SegmentedToggle` (Trips ⁄ Passport) | Same pattern — `.onTapGesture` on `Text`, no button/selected traits, no press feedback. | E |
| M‑04 | `TripDatesCalendar` | Day cells are `.onTapGesture` on a `Text` — no label ("8"), no date context, no selected trait; month arrows have no label. The whole picker is opaque to VoiceOver / Switch Control. | E |
| M‑05 | `WorldMapView` | The map is a `Canvas` + `.onTapGesture`. No accessibility representation of any country, no way for VoiceOver to read visited state or select a country. Canvas‑drawn country labels aren't accessible text. | E |
| M‑06 | Reward overlay (`RewardOverlayView`) | Auto‑dismiss is **6 s** (spec 2–3 s) and **only VoiceOver** extends it to 12 s — **Reduce Motion does not affect the timer**, contrary to the stated requirement. Overlay isn't announced (`UIAccessibility.post(.screenChanged)` not sent; a separate `UIWindow` doesn't move VO focus). | D / E |
| M‑07 | Onboarding tour, Suitcase empty state, Passport/Trips empty state | Dark raster illustrations drawn with `.blendMode(.multiply)` → **invisible / muddy if the system forces dark mode** (v1.1 not shipped, but the brief asks this be tested). | G / C |
| M‑08 | `BuilderChipGrid` | Selected state is **colour‑only** — amber tint + amber border, `lineWidth` unchanged, no check/shape. Colour‑blind users can't tell which chips are picked; VoiceOver gets no `.isSelected`. | E |
| M‑09 | Map surface | Visited vs. want‑to‑go is distinguished by fill **hue/lightness only** (`#D09A42` vs `#7C6636`); wishlist gets a 0.9 pt border — marginal. No pattern/marker. Brief explicitly wants a non‑colour signal here. | E |
| M‑10 | Paywall plan cards | Selected plan = a 0.6 pt border‑colour change only. No radio/check. Easy to miss; no `.isSelected` for VoiceOver. | E / D |
| M‑11 | Many screens | **Small text in brand amber** `Theme.Palette.accent` (~2.9:1 on cream — fails WCAG AA) instead of the text‑safe `navAmber` (~4.5:1): `TripCardView` countdown "in 5d", `SettingsView` "Active", `SearchView` "Visited" sublabel, `ProfileView` initials. Separately, `textSecondary` (#77736C ≈ 4.0:1) and `textTertiary` (#8F8B84 ≈ 2.7:1) body/kicker copy on `#F5F3EF` is below AA app‑wide. | C / E |
| M‑12 | Asset set | **Four incompatible illustration styles** in use: `SuiteLogomark` / `SuitcaseOpen` = flat‑shaded vector; `PassportBook` = loose hand‑drawn sketch; **`SuitcaseClosed` = photorealistic studio JPG** (S1 hero — and shown on the same empty screen as the flat `SuitcaseOpen`); `WorldMap.png` = static raster with 8 amber countries baked in, used as the Passport watermark regardless of real data. | C |
| M‑13 | Bottom nav glyphs | Suitcase/Passport tabs are custom PNGs in `Assets/Nav/`, not the Lucide `luggage` / `book-open` that DESIGN_SYSTEM.md §7 specifies. | C |
| M‑14 | Bottom nav | It's now a solid white edge‑to‑edge bar; DESIGN_SYSTEM.md §6/§8 still specifies a floating glass pill (deliberate late commit `f712d10`, doc not updated). | C |
| M‑15 | `AddVisitView` / `CountryDetailView` | **No visit‑date field** — every visit gets `firstVisitedDate = .now`. The Passport **year‑filter chips segment by when you tapped, not travel year** → useless for any retro‑added history. | F / A |
| M‑16 | Passport → Trips | Filtered through `visibleArchive` (Free = 3 most recent) **and** by year — a Free user filtering to a year they travelled can see 0 trips. "Plan a trip" from the empty Trips view creates an *upcoming* trip that never appears there (list is past‑only) → dead‑feeling flow. | B / H |
| M‑17 | `PassportStats` / `Countries` | Catalog is `Locale.Region.isoRegions` (~250 incl. `EU`, `UN`, `EA`, `IC`, territories) — all pickable as home country and all counted toward "**/ 195**", so `worldPercent` can exceed 100% and "European Union" is a valid home country. Per‑continent counts can exceed the design denominators ("24 / 23"). `cityCount` dedupes by bare name, collapsing e.g. two "San José"s. | F / C |
| M‑18 | `PackingChecklistView` | Row **X deletes an item instantly** (`context.delete` + save) — no confirm, no undo. "Mark trip complete" archives + stamps the passport with no confirm. **"Reopen trip" → re‑complete creates a duplicate `VisitedPlace`** for the same trip every cycle (no dedup on `sourceTripID`). | A / F |
| M‑19 | Settings → Units | `unitsPreference` is written and **never read** — weather is hard‑coded `°C` (`PackingChecklistView` line 337; `WeatherService` sends no `temperature_unit`). Non‑functional setting. | A |
| M‑20 | `PaywallView` | Not scrollable → title + 3 cards + CTA + legal **overflow on small devices / large text**. "SAVE 47%" and "5 days free" are **hard‑coded** (wrong if prices change, user is trial‑ineligible, or non‑USD). `weekly()` mis‑parses comma‑decimal locales → "≈ $48.06/wk". The "Plans unavailable" alert shows **literal Xcode scheme instructions** to end users. Pending / Ask‑to‑Buy purchases just `dismiss()` with no "waiting for approval". | H / J / L |
| M‑21 | PackingChecklist, Settings, NewSuitcase, ContinentDetail, CountryList | `navigationBarBackButtonHidden()` + `toolbar(.hidden)` → **edge‑swipe‑back is disabled**; custom chevron only. | B |
| M‑22 | `ShareCardView` | `renderCard()` (Canvas map @ scale 3) runs **synchronously up to 3× per body pass** → hitch on open. "Save image" gives no success/failure feedback and doesn't handle a denied "Add to Photos" permission. Rendered map may be blank in the offscreen `ImageRenderer` (GeometryReader) — *verify*. | K / D / G |
| M‑23 | `WorldMapView` | Pan offset is never clamped — zoomed in past 3.4×, the user can drag the map into empty black with no rubber‑band and **no recenter control** (semi dead‑end). | A / D |
| M‑24 | PDF export (`makePackingListPDF`) | **No pagination** — a long checklist becomes one oversized non‑A4 page (`max(size.height, 842)`); `TripExportSheet` then previews it at the wrong aspect ratio. Duplicate item names collapse in the PDF (`Row.id = name`). | A |
| M‑25 | `MapViewToggleSheet` / `CountryDetailView` | Cities/Regions rows show "Soon" and **no‑op on tap** (not `.disabled`, no feedback). The Regions tab in the country sheet is a non‑interactive list with no explanation of why. | A |
| M‑26 | `UserSettings.current(in:)` | Can create **duplicate "singletons"** (a `fetch` may miss a pending insert; CloudKit would add a second row; `RootView` reads `.first` with no sort). Called from inside `SettingsView` / `ProfileView` computed `body` properties → **insert during view update**. | F |
| M‑27 | Persistence | Every `context.save()` is `try?` — a write failure (disk full, future CloudKit conflict) is swallowed with **zero user feedback**. | F |
| M‑28 | Whole app | **No `#if DEBUG` anywhere.** All dev launch‑arg handling ships in Release, including **`-proUnlocked`** (forces `isPro = true`) and `-gallery` / `-dataCheck` (swap the root view for internal QA screens). Not reachable from a normal App Store install, but it's a Pro backdoor compiled into the shipping binary. | G / H |
| M‑29 | `FilterChip` (Passport year chips) | Tap target is **32 pt tall** (< 44). | E |
| M‑30 | `SuiteButton` + most `.buttonStyle(.plain)` rows | **No touch‑down feedback**; **no haptics anywhere** in the app (`sensoryFeedback` / feedback generators: 0 occurrences) — including reward moments and purchase. | D |
| M‑31 | `NewSuitcaseFlow` | Back‑chevron button has **no `.accessibilityLabel`** (reads as "Button"). "+ Travellers" secondary button is a **tappable no‑op** at `.opacity(0.5)` (not `.disabled`). | E / A |
| M‑32 | `PurchaseConfirmationView` | Full‑amber screen: "You're Pro." (white on `#D09A42` ≈ 2.3:1) and the 15 pt subcopy (white‑85% ≈ 2:1) **fail WCAG AA**. | C / E |
| M‑33 | `TripDatesCalendar` | Trip dates can be set arbitrarily in the past / far future with no bounds; a past range makes the trip immediately `.past` (can't be packed). First‑weekday is hard‑coded Monday, ignoring `Calendar.firstWeekday`. | A / L |
| M‑34 | Weather far‑future trips | If the trip is entirely beyond Open‑Meteo's 16‑day window, `forecast` returns `[]` → `refresh` **deletes any cached `WeatherDay` and inserts nothing**, and (cache now empty) re‑hits the network on every view appearance. | I / K |

### 🟢 Low / cosmetic (grouped)

| Area | Notes |
|---|---|
| Tokens | `#0A0A0A` literals in production: `Theme.Palette.onAccent`, `textPrimary` (light), `AuthFormView` hero, `PackingListPDF.ink`. Brief says the vigente near‑black is `#14161A`; DESIGN_SYSTEM.md still documents these as `#0A0A0A` — see **Open Questions**. No other hardcoded hex outside the sanctioned exceptions (map surface palette, builder chip tile colours, PDF stylesheet). |
| Copy / dates | `TripCardView` "today"/"tomorrow" is off by time‑of‑day (raw `Date` delta, not calendar days). Year‑spanning trips show no year in the checklist header, end‑year only on the card. `WeatherService` maps WMO code 1–2 (clear / partly cloudy) to the rainy `cloud-sun-rain` glyph. |
| Localization detail | Manual `day`/`days`, `city`/`cities`, `1 visit`/`visits` pluralisation and `NumberFormatter.ordinal` won't localise inside English sentences; country/continent/city names are forced `en_US`. |
| Dead code shipped | `SectionHeader` (only in `ComponentGallery`), `Traveler` model, `Suitcase.name`, `UserSettings.isProSubscriber` (never read/written after init), ~12 unused Lucide assets, `SampleData` seeders + `try! ModelContainer` (dev‑arg‑gated, so not a Release crash — but `inMemoryContainer` is missing `WishlistPlace`). |
| Docs | `ASSETS_INVENTORY.md` stale ("86 SVGs", no `Nav/` glyphs, doesn't flag the JPG). DESIGN_SYSTEM.md not reconciled with the solid‑bar nav or custom nav glyphs. |
| Spelling | "Traveller"/"Travellers" (British) vs American spelling elsewhere ("color", "Log out"). |
| Perf micro | `DateFormatter` created per call in `TripCardView` / `PackingChecklistView.dateRange` / `TripDatesCalendar`. |
| Onboarding | Splash (1.4 s) and "Setting up" (~2.2 s) are fake progress; neither respects Reduce Motion nor announces to VoiceOver; both auto‑advance with no skip. |
| ProBenefits | Benefit icons rendered at 64 pt — a 1.75‑stroke Lucide glyph looks hairline at that size. |
| App icon | Grey‑on‑white, no amber, heavy padding — low shelf impact, off the cream/amber brand. No dark/tinted variants. |
| `ProfileView` | Back chevron labelled "Close" (glyph says back); two redundant "Settings" entry points. |
| `SearchView` | Field has a 1 px near‑black (`textPrimary`) border — heavier than the rest of the app's `border` hairlines. |

---

## 3. Localization (umbrella — 🟡)

There is **no localization infrastructure**: `developmentRegion = en`, `knownRegions = (en, Base)`,
and zero `.strings` / `.stringsdict` / `.xcstrings` / `NSLocalizedString` in the project.
~100% of user‑facing copy is hard‑coded English string literals, many with hard‑coded `\n`
line breaks (`WelcomeView`, `SettingUpView`, `PaywallView`, `PurchaseConfirmationView`, …) and
manual pluralisation. **A Spanish build is not currently possible** without a full string
extraction pass. `TripDatesCalendar`'s weekday row is hard‑coded English + Monday‑first.
Country / city names come from `Locale(identifier: "en_US")` regardless of device language.
Date/number formatting mostly uses `DateFormatter` with fixed `dateFormat` — month names
localise, weekday labels and the `weekly()` price parser do not.

If v1 is intentionally English‑only, that's a product call — but it should be a conscious one,
and the wordmark "Suite." plus the App Store metadata language should match.

---

## 4. Master inventory & verdicts

**Legend:** OK = works as intended · BUG = finding filed (id) · PARTIAL = works with caveats ·
N/A = not applicable · N/I = specified but not implemented.

### Auth & onboarding
| # | Screen | Verdict |
|---|---|---|
| 01 | Splash (`SplashView`) | OK — auto‑advance 1.4 s / tap. Minor: no Reduce‑Motion / VO handling (🟢). |
| 02 | Setting up (`SettingUpView`) | PARTIAL — fake progress, auto‑advances; no Reduce‑Motion / VO (🟢). |
| 03–05 | Onboarding tour (`OnboardingTourView`) | PARTIAL — no Skip; hero art invisible in forced dark mode (M‑07). |
| 06 | Welcome (`WelcomeView`) | OK — Sign in / Skip both wired. |
| 07 | Sign in (`AuthFormView`) | PARTIAL — real `SignInWithAppleButton`, `.fullName` only (good). Terms/Privacy not links (H‑02). Fixed‑height hero may clip on SE / large text (M‑01). |
| 08b | Where are you from? (`HomeCountryView`) | PARTIAL — "Continue" correctly gated on a selection (OK). Catalog includes `EU`/`UN`/pseudo‑codes (M‑17). No date, seeds `VisitedPlace(isHomeCountry:)` (OK). |
| — | `OnboardingFlow` router | OK — save happens on `finish()`; `seedHomeCountry` insert is flushed. |
| A3 | Location permission (`PermissionView .location`) | BUG — throwaway `CLLocationManager`, empty completion, no feature (H‑05). |
| A4 | Notification permission (`PermissionView .notifications`) | BUG — permission asked, nothing scheduled (H‑06). |
| A1/A2 | Forgot password / Check inbox | N/A — Apple‑only auth, deliberately not built. |

### Shell & navigation
| Item | Verdict |
|---|---|
| `RootView` router (onboarding ↔ shell, dev `-screen`) | OK (dev args unguarded — M‑28). |
| `MainAppShell` paged `TabView` + custom bar | PARTIAL — per‑tab nav state is preserved (OK); top safe‑area relies on each tab's `NavigationStack` reinstating it, Map opts out entirely (*verify no status‑bar overlap*). |
| `BottomNavBar` | OK functionally — order map·suitcase·passport, `.isSelected` trait, Reduce‑Motion honoured. Custom glyphs vs spec (M‑13); solid bar vs spec (M‑14). |
| Swipe‑between‑tabs vs map pan | PARTIAL — pan gated to `zoom>3.4` so default drag pages (OK); zoomed‑in you can't swipe to the next tab (M‑23 context). |
| Edge‑swipe‑back | BUG — disabled on 5 screens (M‑21). |
| Deep‑link / state restoration mid‑flow | N/I — no `@SceneStorage`; an in‑progress "New suitcase" is lost on app kill (🟢). |

### Suitcase tab
| # | Screen | Verdict |
|---|---|---|
| S1 | `SuitcaseTabView` (empty / list) | PARTIAL — empty‑state art invisible in dark (M‑07); mixed illustration languages on one screen (M‑12); FAB vs inline add‑card logic OK. |
| — | `TripCardView` | PARTIAL — countdown off‑by‑time‑of‑day (🟢); relied on `Trip.status` (H‑09 fixed); no combined a11y label (M‑01 adjacent). |
| S2a | `NewSuitcaseFlow` basics | PARTIAL — validation OK ("Continue" gated on name+country+dates); no keyboard‑dismiss / footer may be covered by keyboard (M‑01); back button unlabeled (M‑31); trip‑type selection doesn't seed items (Open Q). |
| S2b | `NewSuitcaseFlow` activities | PARTIAL — "Create suitcase" OK; "+ Travellers" is a tappable no‑op (M‑31). |
| — | `TripDatesCalendar` | BUG — inaccessible to VoiceOver (M‑04); no date bounds, hard‑coded Monday‑first (M‑33). |
| — | `BuilderChipGrid` | BUG — colour‑only selection (M‑08). |
| — | `CountryPicker` | PARTIAL — works; no title, no "no results" state, English‑name search only (🟢). |
| S3 | `PackingChecklistView` (live) | PARTIAL — checkbox a11y is good; delete‑X has no confirm/undo (M‑18); weather summary safe; hard `°C` (M‑19). |
| S4 | `PackingChecklistView` (completed) | PARTIAL — "Mark complete"/"Reopen" no confirm; reopen→re‑complete duplicates the stamp (M‑18). |

### Map tab
| # | Screen | Verdict |
|---|---|---|
| 09 | `MapTabView` | PARTIAL — location button dead (H‑05); 4 stacked `.sheet` modifiers (low risk). |
| — | `WorldMapView` | BUG — no VoiceOver representation (M‑05); pan not clamped, no recenter (M‑23); Canvas redraws ~177 detailed paths per gesture frame (*verify perf*). Antimeridian data is pre‑split (OK). |
| — | `WorldMap` / `world.min.json` | OK — 239 territories, no malformed points, loads offline, fails gracefully to `[]` (no error UI if it ever fails — 🟢). |
| M1 | `AddVisitView` | BUG — no visit date (M‑15); un‑visit destroys home seed / stamps (B‑01, H‑10). Row selection has a shape cue (OK). |
| M2 | `CountryDetailView` (bottom sheet) | BUG — un‑visit destructive/unconfirmed (B‑01); territories show a 2‑letter code as title + empty lists (M‑17); Regions tab inert (M‑25); `bigToggle` no `.isSelected` (M‑10 class). |
| M3 | `MapViewToggleSheet` | PARTIAL — only "Countries" works; "Soon" rows no‑op with no feedback (M‑25). |
| M4 | City detail | N/I — deliberately not built (no city coords). |
| — | `WorldCities` | OK — loads offline, graceful fallback; `City.id = name` non‑unique within a country (rare, 🟢). |

### Passport tab
| # | Screen | Verdict |
|---|---|---|
| 11 | `PassportTabView` | PARTIAL — "never show 0" holds in the normal flow (OK) but breaks via B‑01; watermark is the fake static PNG (M‑12); year filter keys off add‑time (M‑15). |
| — | `PassportStats` | BUG — counts non‑UN codes toward /195, `worldPercent` can exceed 100%, city dedupe by bare name (M‑17). Country dedupe by code is correct (OK). |
| P1 | `TripsListView` | PARTIAL — empty art dark‑invisible (M‑07); "Plan a trip" creates a trip that never shows here (M‑16). |
| P2 | Trip detail | N/I — deliberately routes to the read‑only checklist (no photos in v1). |
| P3 | `ContinentDetailView` | OK — strong non‑colour visited cues; no swipe‑back (M‑21); can read "24/23" (M‑17). |
| P4 | `CountryListView` | PARTIAL — "N visits" actually counts records (country + each city + each trip), reads as "N trips" (M‑17). |

### Global / shared
| # | Screen | Verdict |
|---|---|---|
| G1 | `ProfileView` | BUG — "Sign in" dead when signed out (H‑04); initials in low‑contrast amber (M‑11). |
| G2 | `SettingsView` | BUG — "Delete account" dead (H‑01); "Apple ID" dead row; Units/reminders/recaps non‑functional (M‑19, H‑06); logout OK with confirm. `settings` computed prop inserts during body (M‑26). |
| G3 | `SearchView` | BUG — results not tappable (H‑03); has a proper "nothing matches" state (OK). |
| G4 | `ShareCardView` | PARTIAL — triple synchronous render (M‑22); no save feedback / permission handling (M‑22); close + share wired (OK). |
| G5 | `ErrorStateView` | OK — used by the checklist for a missing suitcase; wifi‑off glyph per handoff. |
| — | `PermissionView` | BUG — see A3/A4. |
| Pro1 | `ProBenefitsView` | PARTIAL — has a working close X; advertises unbuilt features (H‑07). |
| Pro1‑1..4 | Unlimited / Templates / Global rank / iCloud sync detail screens | N/I — not built as separate artboards (carousel slides stand in). Note: no fake neighbour usernames anywhere (OK — brief §2 check passes). |
| Pro2 | `PaywallView` | BUG — Terms/Privacy not links (H‑02); overflow on small screens, hard‑coded discount/trial copy, dev‑text alert, silent pending purchase (M‑20); close X is bolted on by each presenter, mis‑placed under the status bar (M‑20 class). |
| Pro3 | Region detail | N/I. |
| — | `UpsellSheet` | OK — per‑moment copy, "Not now" dismiss, drag indicator. |
| — | `PurchaseConfirmationView` | PARTIAL — Reduce‑Motion + VO hold handled (OK); white‑on‑amber text fails AA (M‑32). |
| — | `DataExportSheet` / `TripExportSheet` | OK — gated (Pro), close + empty + error states present; PDF pagination missing (M‑24). |
| R1–R4 | Reward overlays | PARTIAL — render with real values; scale‑and‑fade + Reduce‑Motion for the *entrance* (OK); auto‑dismiss timing & Reduce‑Motion gap (M‑06); not announced to VoiceOver (M‑06). No R4 artboard (documented). |
| 12 | Style sheet / `ComponentGallery` | Dev only. |

### Data integrity (brief §5F) — explicit checks
| Check | Result |
|---|---|
| TripStatus at exact boundaries (start day, end day, single‑day, month/year cross) | **BUG found & FIXED** (H‑09). Now `.active` for the whole first and last calendar day; TZ‑dependent by design (acceptable). |
| VisitedPlace survives its source Trip's deletion | **OK by design** — no relationship, cascade doesn't reach it. *But* the map/add‑visit "un‑visit" toggle deletes it directly (B‑01/H‑10). |
| No stat block shows 0 for a fresh user after onboarding | **OK in the normal flow** (home seed → `1 / 195`, `1%`, "One stamp so far"). **Breaks** via B‑01. Per‑continent rows do show "0 / 54 · 0%" — see Open Questions. |
| New suitcase starts ~15–20% | **OK** — `Suitcase.progress` = `0.18 + 0.82·packedRatio`, verified; seeded‑but‑unpacked items still yield 0.18. |
| CloudKit sync / conflict / dedupe | **N/I** — `SuiteApp` configures no CloudKit container; cannot test; advertised on the paywall (H‑07). |
| CKShare collaborator permission scoping | **N/I** — `Traveler` model only. |
| All SwiftData entities defaulted for CloudKit | **OK** — all 11 `@Model` types: every stored property defaulted, to‑one optional, to‑many `= []`, no `.unique`. |

### Security / privacy (brief §5G) — explicit checks
| Check | Result |
|---|---|
| Repo scan for keys / tokens / secrets (incl. Info.plist, entitlements, `.storekit`, build settings) | **Clean** — none found. Open‑Meteo needs no key; `.storekit` `_developerTeamID` empty. |
| Network calls HTTPS; minimal PII | **OK** — both Open‑Meteo endpoints HTTPS; payload is the destination place name + destination lat/long + dates. **No user id, no device location.** |
| Sign in with Apple — Hide My Email / relay | **N/A (good)** — app requests `.fullName` only, never `.email`; no email is ever collected or logged. No `getCredentialState` revocation check on launch (🟢). Apple `user` id stored in SwiftData, not Keychain (🟢). |
| CloudKit private vs public DB scoping | **N/A** — CloudKit not enabled. |
| Trivial Free→Pro bypass from normal UI (no jailbreak) | **None found** in the UI. `-proUnlocked` launch arg forces Pro and ships in Release (M‑28) — not reachable from an App Store install, but present in the binary. |
| StoreKit 2 validates the transaction before unlocking | **OK** — `isPro` derived only from `.verified` `Transaction.currentEntitlements` / purchase results; unverified ignored; the local `isProSubscriber` bool is never consulted. |
| Info.plist permission strings — present, purpose‑bound, requested at point of use | Location + PhotoLibraryAdd strings present. **Location is requested for a non‑existent feature** (H‑05); notifications likewise (H‑06). PhotoLibraryAdd is correctly triggered only by "Save image". |
| Forced dark mode doesn't break / expose illegible contrast | PARTIAL — nothing crashes; multiply‑blended art disappears (M‑07); `PurchaseConfirmationView` white‑on‑amber ≈ 2:1 (M‑32). |
| Delete account / data wipes everything (incl. cloud) | **N/I** — no such feature (H‑01). |

### Offline (brief §5I)
| Check | Result |
|---|---|
| Local‑first browse/edit offline | OK — SwiftData local; trips, checklist, computed stats all work with no network. |
| Weather fetch failure | OK — `try?` → no weather shown, no crash, **no spinner to hang** (there is no weather loading state). Far‑future trips re‑hit the network each appearance and wipe the cache (M‑34). |
| Offline map (bundled GeoJSON) | OK — all three JSON resources are in the built `.app`; map renders with no network. |
| Reconnect / pending‑sync reconciliation | N/A — no sync. |

### Performance / stability (brief §5K)
| Check | Result |
|---|---|
| Build | `** BUILD SUCCEEDED **`, 0 warnings. |
| Instruments (Leaks / Allocations) | Not runnable here. `RewardPresenter` keeps a `static UIWindow` that can leak if a scene disconnects mid‑overlay (🟢). |
| Stress (many trips / items / countries, fast scroll) | Lists are `LazyVStack` (OK). *Verify on device:* `WorldMapView` Canvas redraw cost during pinch/pan; `ShareCardView` triple render on open. |
| Cold start | Splash 1.4 s + optional "setting up" 1.8 s are deliberate; nothing heavy on the launch path. |

---

## 5. Fixes applied this pass

Both are objective calculation / robustness bugs authorised by brief §6; neither touches
the schema, pricing, Free/Pro limits, or any visual token.

### 5.1 `Suite/Models/Trip.swift` — TripStatus date boundary (H‑09)
```diff
-    var status: TripStatus {
-        let now = Date.now
-        if now < startDate { return .upcoming }
-        if now > endDate { return .past }
-        return .active
-    }
+    var status: TripStatus {
+        let cal = Calendar.current
+        let today = cal.startOfDay(for: .now)
+        let start = cal.startOfDay(for: startDate)
+        let end = cal.startOfDay(for: endDate)
+        if today < start { return .upcoming }
+        if today > end { return .past }
+        return .active
+    }
```
A trip is now `.active` for the whole of its first and last calendar day (and single‑day
trips are `.active` all day), instead of flipping to `.past` at 00:00 on the final day.
Downstream effects are all corrections: the card no longer greys mid‑trip, the trip stays
in "Upcoming", and a Free trip slot no longer frees up a day early.

### 5.2 `Suite/Services/WeatherService.swift` — parallel‑array bounds (H‑11)
```diff
-        return daily.time.indices.map { i in
-            DayForecast(
-                date: df.date(from: daily.time[i]) ?? from,
-                high: daily.temperature_2m_max[i],
-                low: daily.temperature_2m_min[i],
-                precip: (daily.precipitation_probability_max[i] ?? 0) / 100,
-                code: daily.weathercode[i]
-            )
-        }
+        let count = min(daily.time.count, daily.temperature_2m_max.count,
+                        daily.temperature_2m_min.count, daily.weathercode.count)
+        let precips = daily.precipitation_probability_max
+        return (0..<count).map { i in
+            DayForecast(
+                date: df.date(from: daily.time[i]) ?? from,
+                high: daily.temperature_2m_max[i],
+                low: daily.temperature_2m_min[i],
+                precip: ((i < precips.count ? precips[i] : nil) ?? 0) / 100,
+                code: daily.weathercode[i]
+            )
+        }
```
Guards against a ragged Open‑Meteo response instead of force‑indexing into a crash. No
behaviour change for the normal (lockstep) response.

---

## 6. Open questions (not decided, not changed)

1. **`#0A0A0A` vs `#14161A`.** The audit brief says `#14161A` is the current near‑black and
   any `#0A0A0A` in production is a token bug. But `DESIGN_SYSTEM.md` (committed, "the
   `.dc.html` wins") explicitly defines `onAccent` and light `textPrimary` as `#0A0A0A`
   and the auth hero as intentionally `#0A0A0A`. These contradict. Which source wins —
   and should `Theme.Palette.onAccent` / `textPrimary` / `AuthFormView` hero / `PackingListPDF.ink`
   move to `#14161A`? (Mechanical once decided.)
2. **Monospaced‑numbers rule.** `CLAUDE.md` / brief §2: "numbers always monospaced".
   `DESIGN_SYSTEM.md §2` overrides it for big hero stats (Archivo) and the code follows the
   handoff — the Passport "10 / 195", "5%", the `CircularGauge` %, `StatColumn` values and
   `ShareCardView` numerals are all **Archivo, not mono**. Intended (handoff wins) or a
   rule violation to fix?
3. **"Never show 0" scope.** Headline blocks are safe. Do the **per‑continent rows**
   ("Africa 0 / 54 · 0%") count as "stat blocks" that must never show 0, or is 0/N there
   acceptable and informative?
4. **Nav bar.** Solid white edge‑to‑edge bar (current) vs the floating glass pill still in
   `DESIGN_SYSTEM.md §6/§8`. Confirm the solid bar is the final v1 decision and update the doc.
5. **Nav glyphs.** Custom `Assets/Nav/suitcase` + `passport` PNGs vs the spec'd Lucide
   `luggage` / `book-open`. Keep the custom art (and update the doc) or revert to Lucide?
6. **Trip type doesn't seed items.** In `NewSuitcaseFlow.create()` the "Type of trip"
   selection drives only the card icon; only Accommodation / Transport / Activities / Other
   seed items. Picking "Ski & snow" as the trip type adds no ski gear. Intended?
7. **Territories in the catalog.** Should the country list be curated to the 195 (with
   territories bucketed separately and excluded from the "/195" count and `worldPercent`),
   or is counting every ISO region — and allowing "European Union" / ">100%" — acceptable?
8. **Un‑visit semantics (B‑01).** When the country‑level "Visited" pill is turned off,
   should it: (a) only remove the country‑level row and leave city rows + trip stamps,
   (b) confirm first, (c) refuse for `isHomeCountry`, or (d) keep today's "delete everything"
   behaviour (which it says matches the "Been"‑app reference)?
9. **English‑only v1?** Is shipping with no localization infrastructure and en‑US country
   names a deliberate v1 scope call?
10. **Reward auto‑dismiss.** Spec says 2–3 s; code is 6 s (12 s under VoiceOver). Which is
    right, and should Reduce Motion also extend/disable it (currently it doesn't)?
11. **Paywall claims.** iCloud sync / travellers / smart packing / advanced weather /
    city‑region tracking are on the paywall but unbuilt. Gate the copy to what ships, or
    are these landing in v1 after all?

---

## 7. Where this lives

- Report: `QA_AUDIT.md` (this file), on branch `worktree-qa-audit`.
- Two code fixes committed on the same branch: `Suite/Models/Trip.swift`,
  `Suite/Services/WeatherService.swift`.
- Build verified green after the fixes.
