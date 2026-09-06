# Suite — HIG Design Audit

Full UI/UX audit of the app as of batches 1–8 (App shell, Onboarding, Map, Suitcase,
Passport, Global screens, shared components), against Apple Human Interface Guidelines.

- **Platform / framework:** iOS, native SwiftUI
- **Scope:** ~35 screens + the `Theme`/`Typography` token layer + 12 shared components
- **Method:** every view file read against the HIG references for accessibility, colour,
  typography, layout, dark mode, materials, loading, onboarding, modality, feedback, and
  in-app purchase. Contrast ratios computed from the hex values in
  `Suite/Shared/Theme/Theme.swift` / `DESIGN_SYSTEM.md`.
- **Date:** 2026-09-06

---

## Overall assessment — **Needs Work**

The visual system is genuinely strong: one well-built adaptive token layer, a consistent
spacing / radius / type scale, a real shared-component library, disciplined single-accent
use, and considered empty states on nearly every screen.

What's missing is a whole layer of iOS accessibility work that is effectively unimplemented
across all screens — no Dynamic Type, no VoiceOver labels on icon-only controls, several
sub-minimum touch targets, no reduced-motion handling, and an amber-as-text colour that
fails WCAG contrast on light backgrounds. None of these are screen-specific bugs; each is
one decision, applied everywhere. Most fixes are edits to `Theme.swift`, `Typography.swift`,
and ~6 shared components.

> **Design-fidelity note (`CLAUDE.md`):** items #1, #3, and #4 below may faithfully reflect
> the Claude Design handoff. Per the design-fidelity rule they are flagged as conflicts to
> resolve with the designer, not treated as code defects. Where the handoff specifies a
> failing value, the WCAG conflict is a decision for Ivan + the designer, and the
> resolution should be recorded in `DESIGN_SYSTEM.md §1 / §2`.

---

## Findings

Severity: **Critical** (must fix — a11y violation / breaks platform convention) ·
**High** (significant friction / not native) · **Medium** (suboptimal) · **Low** (polish).

### Critical

#### 1. No Dynamic Type support anywhere
- **What:** Every font resolves through `Font.archivo(_:_:)` / `Font.jetBrainsMono(_:_:)`
  in `Typography.swift:15–21`, which call `.custom(name, size:)` with a fixed point size.
  No call uses `relativeTo:`. No `@ScaledMetric`, no `dynamicTypeSize`. Text does not grow
  with the system text-size setting, and the fixed `.frame(height:)` on rows / headers /
  chips would not accommodate it if it did.
- **Why:** *Accessibility — Vision*: "Support larger text sizes… give people the option to
  enlarge text by at least 200 percent… adopt scalable text." *Typography — Supporting
  scalable text*: "If you use a custom font, make sure it implements the same behaviors [as
  system fonts]… verify that your design scales." On iOS this is a common App Store review
  rejection and excludes low-vision users entirely.
- **Fix:** Add a text-style mapping to the font helpers:
  ```swift
  static func archivo(_ size: CGFloat, _ weight: Font.Weight = .regular,
                      relativeTo style: Font.TextStyle = .body) -> Font {
      .custom("Archivo", size: size, relativeTo: style).weight(weight)
  }
  ```
  Anchor each `Font.Suite` ramp entry to a `Font.TextStyle` (`.largeTitle` for `titleXL`,
  `.body` for `body`, `.caption2` for `micro`, …). Replace fixed `.frame(height:)` on list
  rows / chips / headers with `minHeight` + `.fixedSize(horizontal: false, vertical: true)`.
  Ship behind `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` while layouts harden,
  then lift the clamp. Test every screen at XXL and AX5.

#### 2. Icon-only controls have no accessibility labels
- **What:** `BottomNavBar` tabs (`BottomNavBar.swift:16–24`), search / profile / settings-
  gear buttons (`SuitcaseTabView.swift:86–91`, `ProfileView.swift:36–38`), every back
  chevron, the `ellipsis` menu (`PackingChecklistView.swift:111–121`), close "X" buttons,
  the map-pin and "+" FABs (`MapTabView.swift:41–73`), the packing checkbox and delete-X
  (`PackingChecklistView.swift:228–266`), and the flag / heart quick-toggles
  (`CountryDetailView.swift:152–160`) render only a glyph inside a `Button`. VoiceOver
  announces each as "button" with no name.
- **Why:** *Accessibility — Mobility / Vision*: "interface elements [must be] appropriately
  labeled" for VoiceOver, Voice Control, and Switch Control. The entire primary navigation
  is currently unusable with VoiceOver.
- **Fix:** `.accessibilityLabel(_:)` on every icon-only button ("Map", "Search", "Add
  trip", "More options", "Packed" / "Not packed", "Visited", "Want to go"). Active nav tab
  also gets `.accessibilityAddTraits(.isSelected)`. Toggle-shaped controls (`SuiteSwitch`,
  the checklist checkbox, `SegmentedToggle`) need `.accessibilityAddTraits(.isToggle)` /
  `.isButton` and a value — they are `onTapGesture` on shapes today, not real `Toggle` /
  `Picker` (`SuiteSwitch.swift:18`, `SegmentedToggle.swift:26`).

#### 3. Amber used as a text colour fails contrast on light backgrounds
- **What:** `Theme.Palette.accent` `#D09A42` is used as a *foreground text* colour for the
  hero stat numbers (`StatBlock.swift:18`, `PassportTabView.swift:142`), trip countdowns at
  11 pt (`TripCardView.swift:37`), section counters (`PackingChecklistView.swift:196`), the
  "% ready" figures, and `accentHigh` for links. Measured contrast:
  - accent on `surface` `#FFFFFF` ≈ **2.5:1**
  - accent on `ground` `#F5F3EF` ≈ **2.3:1**
- **Why:** *Accessibility — Vision* contrast table: 4.5:1 for text up to 17 pt, 3:1 for
  18 pt+ and for bold. Amber-on-white fails even the large-bold 3:1 bar, so the 40 pt
  `statXL` numbers — the visual centrepiece of the Passport — do not meet the minimum.
  *Colour — Inclusive colour*: "insufficient contrast can cause icons and text to blend
  with the background."
  - Amber as a *fill* with dark `onAccent` text is fine (≈ 7.9:1).
  - Amber-on-dark in dark mode passes (≈ 7.4:1). The problem is specific to amber
    glyphs / text on the light palette.
- **Fix:** Reserve amber for fills, borders, progress bars, and underlines; set the
  numerals in `textPrimary`. If amber numerals are a hard handoff requirement, add an
  `accentText` token (~`#8A6220`, ≈ 4.6:1 on white) used *only* where the accent is the
  text colour, and raise the single-accent-rule conflict with the designer. Touches
  `DESIGN_SYSTEM.md §1` — a deliberate decision, not a code-only change.

#### 4. Sub-minimum touch targets on core controls
- **What:**
  - `BottomNavBar` — tappable label is `.frame(width: 28, height: 28).frame(maxWidth:
    .infinity)` (`BottomNavBar.swift:20–21`): full width but ~28 pt tall, inside a 78 pt
    bar that is top-aligned with 16 pt padding → large dead zone below each icon.
  - `SuiteSwitch` — `.contentShape(Capsule())` on a 50 × 30 frame
    (`SuiteSwitch.swift:16–17`): 30 pt tall.
  - Packing checkbox — 22 × 22 hit area, no expanded `contentShape`
    (`PackingChecklistView.swift:246`); delete-X — 26 × 26 (`:263`). Below the 28 pt
    absolute minimum.
  - `FilterChip` — 32 pt tall (`FilterChip.swift:16`); Map / Country quick-toggles —
    38 × 38.
  - Text-only buttons ("Skip for now", "Not now", "Cancel", "Done", "Restore") — only the
    label is the target, ~20–24 pt tall.
- **Why:** *Accessibility — Mobility*: "mobile 44×44 pt [default], 28×28 pt [minimum]…
  Consider spacing between controls as important as size." Primary navigation and the
  most-repeated action in the app (ticking off packing items) are the worst offenders.
- **Fix:** `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(Rectangle())` on every
  `Button` label currently smaller. Keep the visible chip / switch small; expand only the
  hit area. For `BottomNavBar`, make each tab's target the full bar height. For
  `SuiteSwitch`, let the 44 pt row height be the target.

### High

#### 5. Custom bottom nav instead of a `TabView`
- **What:** `MainAppShell.swift:18–32` switches tab content by hand and stacks a custom
  `BottomNavBar`; each tab view hosts its own `NavigationStack`.
- **Why:** *Layout — Mobile*: the tab bar is the standard primary-nav pattern, and the
  system `TabView` provides behaviour now missing — re-tap-to-pop-to-root, scroll-to-top,
  VoiceOver tab rotor semantics, state restoration, `hidesBottomBarWhenPushed`, the
  iOS 18+ adaptive / floating treatment. *Accessibility — Cognitive*: "Prefer system
  gestures and behaviors people are already familiar with."
- **Fix / trade-off:** The bespoke filled-amber active glyphs are the reason for the custom
  bar; they don't survive a stock `TabView` cleanly. Options:
  - (a) move to `TabView`, accept simpler active states;
  - (b) keep the custom bar but add the missing accessibility traits (#2) and wire
    re-selection to pop the active stack.
  Lean: **(b) now, revisit (a) post-launch.** Needs a product call from Ivan.

#### 6. Hidden nav bars likely disable edge-swipe back
- **What:** Nearly every pushed screen uses `.navigationBarBackButtonHidden()` **and**
  `.toolbar(.hidden, for: .navigationBar)` with a custom chevron header
  (`PackingChecklistView.swift:64–65`, `CountryListView.swift:59–60`,
  `ContinentDetailView.swift:46–47`, `SettingsView.swift:98–99`).
- **Why:** Fully hiding the navigation bar commonly disables the interactive pop
  (edge-swipe-back) gesture iOS users rely on. *Accessibility — Mobility*: "Offer
  alternatives to gestures" — and don't remove the expected one.
- **Fix:** Use `.navigationBarBackButtonHidden(true)` only, hide the bar background with
  `.toolbarBackground(.hidden, for: .navigationBar)`, keep the custom header as an overlay.
  Verify swipe-back still fires on each pushed screen; if not, re-enable via a
  `UINavigationController` delegate shim.

#### 7. No press-state feedback on any button
- **What:** `.buttonStyle(.plain)` on essentially every `Button` (trip cards, chips, nav
  icons, list rows, plan cards). Tapping produces no opacity / scale change.
- **Why:** *Feedback — Best practices*: "Provide clear, consistent feedback as people
  interact with your app… understand the results of actions." A tappable card that doesn't
  react on touch-down reads as non-interactive.
- **Fix:** One shared style, swapped in for `.plain` where the whole surface is the button:
  ```swift
  struct SuitePressStyle: ButtonStyle {
      func makeBody(configuration: Configuration) -> some View {
          configuration.label
              .opacity(configuration.isPressed ? 0.62 : 1)
              .scaleEffect(configuration.isPressed ? 0.985 : 1)
              .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
      }
  }
  ```

#### 8. Animations don't respect Reduce Motion
- **What:** `PurchaseConfirmationView.swift:86–96` runs an expanding pulse-ring + spring
  "pop" + scale-in sequence; `RewardOverlayView.swift:23–24` springs and scales;
  `SettingUpView` animates a continuous ring; `SuiteSwitch.swift:19` uses `.snappy`. None
  check `accessibilityReduceMotion`.
- **Why:** *Accessibility — Cognitive*: "When [Reduce Motion] is active… reduce automatic
  and repetitive animations, including zooming, scaling, and peripheral motion… replace
  transitions… with fades." The purchase-confirmation pulse rings are exactly the
  peripheral zoom motion called out.
- **Fix:** `@Environment(\.accessibilityReduceMotion) private var reduceMotion`; when true,
  skip the pulse / pop, replace scale-in with an opacity fade, swap springs for `.easeOut`.
  A small `reduceMotion`-aware helper covers all four sites.

#### 10. Paywall — dismissal, trial copy, localization
- **What:** `PaywallView` has no close control in its own body — `ProBenefitsView.swift:96–
  102` and `UpsellSheet.swift:58–65` each bolt a close "X" on via `.overlay`, so a
  standalone presentation (Settings → `showPro`, `-screen paywall`) depends on the
  presenter adding one. The footer text is hardcoded `"5-day free trial, then billed
  yearly. Cancel anytime."` (`PaywallView.swift:108`) regardless of whether Monthly or
  Lifetime is selected; `weekly()` / `SAVE 47%` assume a `$` string (`:200–204`).
- **Why:** *Modality*: "Always give people an obvious way to dismiss a modal view."
  *In-App Purchase — Making signup effortless*: "specify the price and duration for each
  option… Clearly describe how a free trial works… billing amount, correctly localized."
  The current footer misstates terms for two of the three plans.
- **Fix:** Permanent close button in `PaywallView`'s own top-leading corner; remove the
  per-presenter overlays. Trial / billing line switches on `plan`. Derive weekly figure and
  savings from `Product.priceFormatStyle` / `Decimal` values, not string parsing.

### Medium

#### 11. Nested full-screen covers presented from sheets
- **What:** `UpsellSheet` (a `.sheet`) presents `PaywallView` as a `.fullScreenCover`
  (`UpsellSheet.swift:57`); `ProBenefitsView` (a `.fullScreenCover`) presents `PaywallView`
  as another `.fullScreenCover` (`ProBenefitsView.swift:94`); `PaywallView` then swaps its
  whole body for `PurchaseConfirmationView`.
- **Why:** *Modality*: "Let people dismiss a modal view before presenting another one…
  presenting multiple views adds to people's cognitive load, especially when a modal view
  hides another one." Three stacked modals with mixed styles is hard to retrace.
- **Fix:** Collapse benefits → plans → confirmation into one modal with internal steps
  (a single `NavigationStack` or a paged `TabView`), or present the paywall by *replacing*
  the upsell sheet rather than stacking on top of it.

#### 12. Hardcoded top offsets won't adapt across devices
- **What:** `AuthFormView.swift` uses `.padding(.top, 58)` (back button), `.padding(.top,
  120)` / `Spacer().frame(height: 236)` (hero); `HomeCountryView.swift:56` `.padding(.top,
  60)`; `PaywallView.swift:59` `Spacer().frame(height: 188)`. Tuned to the 390 × 844 design
  canvas.
- **Why:** *Layout — Adaptability*: "respect system-defined safe areas… specifying layout
  modifiers." On a 375 pt SE (no notch) these over-pad; on a 440 pt Pro Max / Dynamic
  Island they can misalign the hero and back button.
- **Fix:** `.safeAreaInset(edge: .top)` for the back button; anchor the hero with
  `GeometryReader` / ratio spacers or `.containerRelativeFrame`; read `\.safeAreaInsets`
  instead of literal status-bar constants.

#### 13. `myCountriesCard` header navigates via `onTapGesture`
- **What:** `PassportTabView.swift:200–201` — the "My countries ›" header row is an
  `HStack` with `.contentShape(Rectangle()).onTapGesture { path.append(...) }`, not a
  `Button` / `NavigationLink`.
- **Why:** *Accessibility*: no `.isButton` trait, not focusable as a control, no press
  feedback; height is only ~40 pt (two text lines) — another sub-44 target. *Feedback*:
  looks identical to the static card titles above it.
- **Fix:** `Button` / `NavigationLink(value:)` with `minHeight: 44` and `SuitePressStyle`.

#### 9. Time-boxed views auto-dismiss before copy can be read
- **What:** `RewardOverlayView` auto-closes after 3.4 s (`:26–29`) while showing a headline
  + a full sentence; `PurchaseConfirmationView` calls `onDone()` after 4.5 s (`:80–83`)
  while showing two paragraphs.
- **Why:** *Accessibility — Cognitive*: "Minimize use of time-boxed interface elements…
  can be problematic for people who need longer to process information, and for people who
  use assistive technologies." VoiceOver users can't hear the whole message in 3.4 s.
- **Fix:** Lengthen the timer (≥ 6 s), pause it while `UIAccessibility.isVoiceOverRunning`,
  ensure tap-to-dismiss covers the whole card, add an explicit "Done" to the reward
  overlay.

### Low / polish

- **Icon stroke mismatch:** `Theme.Icon.stroke = 1.6` (`Theme.swift:103`) vs 1.75 in
  `DESIGN_SYSTEM.md §7` and `CLAUDE.md`. Reconcile doc and code.
- **`textTertiary` on meaningful glyphs:** `#8F8B84` ≈ 3.1:1 on `ground` — scrapes the 3:1
  non-text minimum for the search icon, weather icon, trailing chevrons, with no margin.
  Nudge `textTertiary` darker or use `textSecondary` for glyphs that carry meaning.
- **`SearchView` has no "no results" state** (`SearchView.swift:87–93`): empty
  `LazyVStack` under a "0 results" label. Add a brief empty message.
- **Bottom-nav background doesn't reach the screen edge:** `BottomNavBar` is a 78 pt
  `surface` frame in a plain `VStack` (`MainAppShell.swift:19–31`); the home-indicator
  strip below shows `ground`. *Layout*: "backgrounds… extend to the edges." Add
  `.background(Theme.Palette.surface).ignoresSafeArea(edge: .bottom)` on the bar.
- **All-caps kicker labels at 10–11 pt** (`KickerLabel`, `micro`): fine as a brand device,
  but all-caps hurts VoiceOver pronunciation and readability at that size — ensure the
  accessible label is the natural-case string.
- **Spelling drift:** "Traveller" / "travellers" (`ProfileView.swift:17`,
  `ProBenefitsView.swift:21`) vs "Travelers" in `CLAUDE.md`. Pick one.
- **`try? context.save()` everywhere:** silent on failure — violates *Feedback*'s "show
  people when a command can't be carried out." At least log the failure path.
- **No haptics** on packing an item, completing a trip, or a reward moment. *Feedback*:
  pair these with `.sensoryFeedback` / `UIImpactFeedbackGenerator`.

---

## What the app does well

- **Token layer is well constructed.** `Color(light:dark:)` in `Color+Hex.swift` gives
  every palette entry an adaptive light / dark value from the start, and no screen defines a
  one-off appearance toggle — correct per *Dark Mode*: "Avoid offering an app-specific
  appearance setting."
- **Consistent scales.** `Theme.Space` / `Radius` / `Size` are used throughout rather than
  magic numbers (the hardcoded top offsets in #12 are the main exception).
- **Real component library.** `SuiteButton`, `SuiteCard`, `StatBlock`, `SuiteProgressBar`,
  `FilterChip`, `SegmentedToggle` keep the screens coherent.
- **Empty states almost everywhere.** Suitcase, Passport, Trips log, checklist, country
  lists all have a considered zero-data screen with a clear CTA.
- **Sheets done right.** `presentationDetents`, `presentationDragIndicator`,
  `presentationBackground` on the Country and Map-toggle sheets.
- **Single-accent discipline** holds, with the multi-colour category / flag exception
  scoped exactly where `DESIGN_SYSTEM.md` says.
- **IAP fundamentals present.** Three distinguishable plans with price + duration, a
  visible "Restore", a Terms link, and reliance on the **system purchase confirmation
  sheet** rather than replicating it — all correct per *In-App Purchase*.
- **Copy voice** is concise and human ("Never pack at 2am again.", "One tap with Apple.
  Your trips stay on your device.").

---

## Suggested changes — prioritised by severity × effort

| # | Change | Severity | Effort | Phase |
|---|---|---|---|---|
| 2 | Accessibility labels on icon-only controls | Critical | Low | 1 |
| 4 | Touch targets ≥ 44 pt | Critical | Low–Med | 1 |
| 7 | Press-state feedback on buttons | High | Low | 1 |
| 8 | Reduce Motion handling | High | Low | 1 |
| 3 | Amber-as-text contrast decision | Critical | Low code / designer sign-off | 1 (raise now) |
| 1 | Dynamic Type + layout hardening | Critical | High | 2 |
| 6 | Hidden nav bar / edge-swipe back | High | Med | 2 |
| 10 | Paywall dismiss + trial copy + localization | High | Med | 2 |
| 12 | Device-adaptive top offsets | Medium | Med | 3 |
| 13 | `myCountriesCard` → real Button | Medium | Low | 3 |
| 11 | Collapse nested modals | Medium | Med | 3 |
| 5 | Custom bottom nav → `TabView` | High feel / low correctness | High + product call | Decide separately |
| 9 | Time-boxed auto-dismiss | Low | Low | Rolling |
| — | Polish batch (stroke, contrast nudge, empty state, haptics, spelling) | Low | Low each | Rolling |

### Phase 1 — accessibility & feedback pass (~2–3 days, mostly shared components)

Small, localized, and unblocks an App Store submission.

1. **VoiceOver labels** — `.accessibilityLabel(_:)` on every icon-only `Button`
   (`BottomNavBar`, `SuitcaseTabView`, `PassportTabView`, `PackingChecklistView`,
   `CountryDetailView`, `MapTabView`, `ProfileView`, `SettingsView`). Active nav tab gets
   `.accessibilityAddTraits(.isSelected)`.
2. **Toggle semantics** — `SuiteSwitch`, `SegmentedToggle`, checklist checkbox get
   `.isToggle` / `.isButton` + a value; prefer rebuilding `SuiteSwitch` on a real `Toggle`.
3. **44 pt targets** — `.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())` on
   every undersized `Button` label; expand hit area only, keep visuals.
4. **Shared press style** — new `Suite/Shared/Components/SuitePressStyle.swift`; swap in for
   `.buttonStyle(.plain)` at whole-surface call sites.
5. **Reduce Motion** — gate the pulse / pop / scale-in in `PurchaseConfirmationView`,
   `RewardOverlayView`, `SettingUpView`, `SuiteSwitch`.
6. **Raise the amber-text contrast conflict** with Ivan / the designer; on sign-off, apply
   the `Theme.swift` + `DESIGN_SYSTEM.md §1` change.

### Phase 2 — platform conventions (~1 week)

1. **Dynamic Type** — `relativeTo:` on the font helpers, anchor each ramp entry to a
   `Font.TextStyle`, replace fixed row heights with `minHeight` + `.fixedSize`. Ship behind
   an `.accessibility3` clamp, then lift. Test every screen at XXL and AX5.
2. **Fix hidden-nav-bar back gesture** — `PackingChecklistView`, `CountryListView`,
   `ContinentDetailView`, `SettingsView`: `.navigationBarBackButtonHidden(true)` +
   `.toolbarBackground(.hidden, for: .navigationBar)`, custom header as overlay, verify
   swipe-back.
3. **Paywall** — permanent close button in `PaywallView`'s own body; delete per-presenter
   overlay closes; trial / billing footer switches on `plan`; weekly + "SAVE %" from
   `Product` decimals.

### Phase 3 — adaptability & structure (~2–4 days)

1. **Device-adaptive spacing** — replace literal top offsets (58 / 60 / 120 / 188 / 236) in
   `AuthFormView`, `HomeCountryView`, `PaywallView` with `.safeAreaInset(edge: .top)` /
   ratio-based hero sizing. Test on SE (375 pt) and Pro Max (440 pt).
2. **`myCountriesCard` header** — `onTapGesture` → `Button` / `NavigationLink(value:)` with
   `minHeight: 44` and `SuitePressStyle`.
3. **Collapse the upsell → plans → confirmation stack** — one modal with internal steps.
4. **Nav-bar background to the screen edge** — `MainAppShell.swift:29`.

### Decide separately

**#5 custom bottom nav vs `TabView`.** Not a bug, but it's why the shell doesn't feel fully
native. Real cost to change (bespoke active glyphs). Lean: keep the custom bar + add
accessibility traits + re-selection-pops-stack now; revisit `TabView` post-launch. Needs
Ivan's call.

### Rolling polish (do as you touch each file)

- Reward / purchase timers → ≥ 6 s, pause under VoiceOver, add explicit "Done".
- `Theme.Icon.stroke` 1.6 → 1.75.
- `textTertiary` on meaningful glyphs — nudge darker or use `textSecondary`.
- `SearchView` "no results" empty state.
- "Traveller" / "travellers" → align with `CLAUDE.md`.
- Replace silent `try? context.save()` with a logged failure path.
- Add `.sensoryFeedback` on packing an item, trip completion, reward moments.

### Suggested order

Phase 1 in full → 2.1 Dynamic Type (largest single effort) → rest of Phase 2 → Phase 3 →
decide #5 → polish rolling.

---

## Platform-specific notes (iOS / SwiftUI)

- The framework is native SwiftUI, so HIG terms map directly: "tab bar" = `TabView` (#5),
  "scalable text" = Dynamic Type / `.custom(_:size:relativeTo:)` (#1), "safe area" =
  `\.safeAreaInsets` / `.safeAreaInset` (#12), "Reduce Motion" =
  `\.accessibilityReduceMotion` (#8).
- Ship-blockers: #1, #2, #4, and the #3 decision. Everything else is native-feel or polish.
- The app **correctly** relies on the system StoreKit purchase confirmation sheet rather
  than replicating it — keep it that way (*In-App Purchase*: "Use the default confirmation
  sheet. Don't modify or replicate this sheet.").
