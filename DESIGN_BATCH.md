# Suite — Design & UX Learnings, Compiled

Source: six video transcripts on mobile UI/UX, redesign technique, and AI-assisted design process. Filtered and cross-referenced against Suite's existing product docs and locked decisions.

---

## Part 1 — What We Learned

### 1. Mobile navigation & structure
- Bottom tab bar: 3–4 icons is ideal, 5 is the hard ceiling. All tap targets ≥44px.
- Nav and actions should be contextual — they change per screen (e.g. editing hides the tab bar, reveals format/share icons instead).
- Alternative to a tab bar: turn the "sidebar" into a full home page (recents + counts up top), freeing the bottom for one big primary action.
- One screen does one job (except the true home screen) — new functionality gets a new page, not a denser layout on an existing one.
- Bottom sheets keep the user in context for secondary choices (picking a template, etc.) — any height, gesture-dismissible.
- The "+" button pattern: opens either a small menu, or jumps straight to an input with the keyboard already up.

### 2. Layout & hierarchy
- Mobile type and spacing don't shrink — they often grow (iOS base font is 17px vs. macOS's 13px).
- Pick **one** scroll direction per section on mobile (vertical stack *or* horizontal scroll) — desktop dashboards can extend in both directions at once, mobile can't.
- Hierarchy comes from size + position + color *together* — contrast is what reads, not any single attribute alone.
- Grids (12-col/8px) are guidelines for repeating, structured content, not a universal law — consistent whitespace matters more. The 4pt spacing system earns its keep because it's infinitely halvable (consistency), not because of inherent beauty.
- Four building blocks: cards, text/links, images, inputs. Avoid double-nesting cards (padding-on-padding cramps space) — prefer whitespace grouping over a second container when possible.

### 3. Typography
- One font family is almost always enough.
- Tighten letter-spacing (-2% to -3%) and drop line-height to 110–120% on large headers for an instant "pro" look.
- Cap font-size variety: ~6 sizes for marketing/landing pages, rarely above 24px on dense dashboards.

### 4. Color
- Start from one primary/brand color → lighten for backgrounds, darken for text — that's most of a working color ramp.
- Layer semantic color on top with real meaning (blue = trust, red = danger, yellow = warning, green = success) — color should signal, not decorate.
- Never let an AI choose colors unsupervised — it defaults to bright, clashing palettes.

### 5. Dark mode & depth
- Light borders read as too high-contrast in dark mode — dial down.
- No shadows for depth in dark mode — use a **lighter** card fill than the background instead.
- Bright chips need dimmed saturation/brightness; hierarchy gets carried by the text instead.
- Dark mode has real room for deep purples/reds/greens, not just navy/gray.
- Light-mode shadows: lower opacity + more blur reads natural. Cards need subtle shadows, floating content (popovers) needs stronger ones. If the shadow is the first thing you notice, it's too strong.

### 6. Icons
- Consistency *within a visual zone* is non-negotiable; mixing styles *across* zones (nav vs. content vs. reward moments) is fine.
- Icon size should match the font's line-height, not be eyeballed.
- Icon *weight* can be a legitimate state signifier (thin = inactive, filled = active) — more refined than a color-only state change.
- Missing icons force reading over scanning — add them where they help.
- Well-known icons (house, bookmark, profile) don't need labels; ambiguous ones benefit from a tooltip.

### 7. Feedback, motion & micro-interactions
- Every interactive element needs visible states: default / hover / active-pressed / disabled, plus loading where relevant. Inputs need focus / error / warning states too.
- Instant visual acknowledgment on tap matters even before the "real" transition happens — a delayed response reads as broken.
- Micro-interactions confirm actions beyond the base state (a "copied" chip sliding up) — small individually, but they compound into a premium feel across the whole app.
- Haptics should vary by weight/context: light for frequent, low-stakes taps; heavier for rare, significant actions.
- For AI-assisted builds: complex animations should be decomposed into explicit sub-steps in the prompt/spec, not requested as one vague instruction — this reliably produces far better results than one-shotting it.
- Swipe navigation should animate the background too, not just slide the foreground; bottom sheets pair well with a background zoom-out/zoom-in.

### 8. Empty states & redundancy
- Design the first-run empty state deliberately: draw attention to the primary action, don't clutter with placeholder invitations.
- No-results states need their own treatment: acknowledge the specific query, offer a suggestion (e.g. for a typo), provide a clear way out.
- Custom illustrations (from one consistent base) elevate empty states over generic text — but the illustration style has to match the app's established identity, not import a different one wholesale.
- Remove anything a native gesture already covers (an arrow next to a swipeable element), and cut decorative elements that aren't doing real work.
- Never leave a stat/progress display at a genuinely discouraging zero when a real, honest head start can be shown instead.

### 9. Conversion & behavioral psychology
- **Smart defaults** — pre-fill the most common choice rather than a blank form; most users never change defaults, and reading them as recommendations lowers the decision burden.
- **Goal-gradient effect** — never start progress at 0% if there's a real, honest head start to show; proximity to completion is itself motivating.
- **Reciprocity** — give something genuinely useful before asking for signup/payment, rather than gating results behind a wall.
- **IKEA/endowment effect** — letting someone make a real choice before the signup wall makes leaving feel like abandoning something built, not skipping a form.
- **Loss aversion** — framing around what's lost is a stronger motivator than framing around what's gained, but tips into manipulative territory quickly — use carefully, if at all, in a calm/premium product.
- **Contrast effect** — a price shown in isolation feels larger than the same price shown right after a bigger, relevant number; anchor pricing against something the user just experienced.

### 10. Working with AI on design — the "four levels" framework
- **Level 1** — a bare prompt produces clean-but-generic output ("AI slop"): no one made a decision, so it has no point of view.
- **Level 2** — feeding it real direction (a design system, references) measurably improves consistency and hints of intent, but plateaus without a trained eye steering it.
- **Level 3** — piling on *everything at once* makes results **worse than level 1**: components stop matching, because no single point of view is reconciling all the inputs.
- **Level 4** — a human decides what to *cut* (not what to add), commits to one governing idea, and applies it to every single screen. This is the only level that produces real differentiation, and it specifically wins on human-native execution details AI can't infer on its own.
- The real ceiling for AI-assisted design is the quality of direction given, not the model — this gap widens as models improve, even as the baseline rises for everyone.
- Practical takeaways: never let AI choose colors or layout unsupervised; review new output against "does this still hold together on screen 100," not just in isolation; keep one governing idea explicit and central to every brief, especially across many separate build sessions, to avoid the level-3 failure mode.

### 11. General design QA checklist
- Map the full user flow before building — missing edge cases (no search/no skip when genuinely needed) are felt instantly by users even when easy to overlook while designing.
- Consistency of small components (corner radius, functionally-equivalent buttons) is one of the cheapest, highest-impact fixes available.
- Charts should prioritize legibility over decoration — visible axes, a bar count that matches the real data, never sacrifice readability for a "prettier" shape.

---

## What Suite already gets right (no change needed)

- 3-tab structure already sits inside the "3–4 icons ideal" range.
- The seeded-stats decision (home country seeds the passport, suitcase readiness opens at 15–20%) is already the strongest version of the goal-gradient principle — a real head start, not a cosmetic one.
- Reward-overlay spec already ties auto-dismiss to Reduce Motion and accounts for VoiceOver, ahead of most of what these videos describe.
- Numbers-monospaced/words-never and uniform Lucide stroke weight are already the disciplined version of the typography and icon-consistency advice above.
- The onboarding screen's lack of a skip option is an intentional, correct exception to the general "always offer a skip" guidance — it exists specifically to support the seeded-stats decision.

---

## Part 2 — Batches: What to Change or Decide

### Batch A — Decisions to resolve before building further

*Resolved 2026-09-09 — full rules in `DESIGN_SYSTEM.md` §10. Two items still want Ivan's
explicit nod (marked below); the rest write down what the build already does.*

- [x] **Semantic color exception.** → §10.1. `danger` (`#D96A4A`/`#E07C5C`) is the only
  semantic hue: destructive labels + error/validation text, nothing else. Success and
  warning are structural, never colour (no green, no yellow). `danger` never carries
  meaning without an accompanying verb/icon/text — keeps the colourblind rule intact.
- [x] **Haptics strategy.** → §10.2. **PROPOSED — confirm.** Four tiers on iOS 17
  `.sensoryFeedback`: selection (tab switch, packing-item toggle, chips), light impact
  (add item, save field), success (only with a reward overlay / purchase), warning
  (Free-limit block, failed export). Never two haptics on one gesture.
- [ ] **Icon weight as a state signifier.** → §10.3. **RECOMMENDATION: no.** One Lucide
  stroke (1.75) everywhere; no thin↔filled swap on the same glyph. State stays
  structural (tint / capsule / label / checkmark), as nav and Passport already do.
  *Ivan to confirm this is the call.*
- [x] **Icon-zone exception.** → §10.4. Reward overlay is its own zone; its badges are
  currently still Lucide at 40 pt over `RayBurst`. If bespoke stamp/suitcase artwork is
  ever swapped in *there only*, that's a sanctioned zone exception, documented now.
- [x] **Empty-state illustration style.** → §10.5. Default stays Lucide glyph + copy.
  Any future illustration must derive from the `SuiteLogomark`/`SuitcaseOpen`/
  `PassportBook`/`WorldMap` objects, mono/duotone amber-on-ground. No mascot, no faces.

### Batch B — Screen & component-level passes
- [ ] **Dark-mode elevation audit.** Confirm depth comes from a lighter card fill (not shadows), borders are dialed down rather than bright, and any chip/badge saturation is checked against the near-black base.
- [ ] **Trip card hierarchy** (Suitcase list). Destination name large/bold/top, dates/countdown smaller below; consider an icon+line motif if a trip ever needs to show a route or multi-stop structure.
- [ ] **Corner-radius consistency.** Set one radius value as a named constant for all small components (buttons, chips, inputs) rather than letting it vary screen to screen.
- [ ] **Card-nesting check.** Audit the Suitcase list → trip card → item-card structure once built for any double-nested containers; prefer whitespace grouping over a second container.
- [ ] **Progressive disclosure on forms.** Keep New Trip / New Suitcase forms to core fields (destination, dates, name) visible by default; collapse anything secondary behind an expandable section if the form grows.
- [ ] **Template picker as a bottom sheet.** Use for choosing a saved packing template mid-flow, keeping the user in the suitcase-editing context.
- [ ] **Overlay gradients.** Anywhere text sits over an image (Map tab, Passport stamps), use a gradient (optionally with progressive blur) rather than a flat scrim — matches the "dimmed, not opaque" approach already used for reward overlays.
- [ ] **Redundant-element pass.** Once those screens exist, remove any leftover chevrons/arrows that duplicate a native swipe gesture already in place.

### Batch C — Paywall, pricing & copy
- [ ] **Reciprocity-based upsell copy.** At the point of friction (the 1-suitcase cap is the sharpest, per the Pro Features doc), show the specific unlock ("Unlimited suitcases, templates, sync") rather than a generic "Upgrade to Pro" banner.
- [ ] **Pricing-screen anchoring.** Give visual weight to the price, not the plan name. State the effective monthly savings on the annual plan explicitly. Consider anchoring against something just experienced (what this trip would have needed) rather than presenting the number cold.
- [ ] **Avoid loss-framing/dark-pattern copy** at the paywall — no manufactured-urgency language. Stays consistent with Suite's calm, considered tone rather than an anxious one.

### Batch D — Motion, feedback & micro-interactions
- [ ] **Tiered feedback.** Instant, lightweight confirmation on checking a packing item (no wait on sync), kept separate from the larger celebratory reward overlay that fires only once a suitcase is fully packed.
- [ ] **Export confirmation.** Add a small micro-interaction (e.g. a brief confirmation chip) when a PDF/Messages export completes, not a silent success.
- [ ] **Decomposed animation specs.** Any future motion spec (tab transitions, packing-check animation, suitcase-packed transition) should be written into the Claude Code briefing as an explicit sequence of sub-steps, not a single-sentence description of the end effect.

### Batch E — Process guardrails for the ongoing build
- [ ] Treat the single amber-on-near-black, restrained identity as the governing idea every new screen is checked against — the "one idea, applied everywhere" standard, not just a style guide referenced loosely.
- [ ] Guard against the "level-3 Frankenstein" risk in batch prompts: keep each Claude Code briefing anchored to one clear point of view rather than stacking too many references or instructions into a single prompt.
- [ ] Add a periodic review checkpoint — "does this still hold on screen 100, not just this one" — once more batches land, checking new screens against the canonical docs rather than only judging each screen in isolation.
