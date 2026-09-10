# Suite — Social layer (friends)

Built from the friends/social addendum. There was **no design handoff bundle**
in the repo for these screens (`suite-design-prompt*.md` don't exist here), and
Ivan directed building it anyway, ignoring that gap. Every value below was
derived from `DESIGN_SYSTEM.md` + existing components, not from a handoff.
Flagged so it can be reconciled against the real designs later.

## What shipped

**New screens / components**
- `Passport/Friends/AddFriendsView.swift` — full-screen sheet: amber-on-black QR
  (`QRCodeView.swift`, CoreImage), monospace code, Share pill (`ShareLink`),
  "Enter a code" field + "Send request".
- `Passport/Friends/FriendProfileView.swift` — guest passport view, amber-underlined
  "<Name>'s Passport" header, reused "In total" stat block, stamp grid (flags +
  ISO), "Trips together" row; **locked variant** (blurred grid + `globe-lock` +
  one line) when the friend hasn't shared.
- `Passport/Friends/FriendRequestCard.swift` — card, not a screen: initial avatar,
  "wants to be your friend", Accept (amber) / Decline (outline).
- `Passport/Friends/FriendsListView.swift` — the Friends segment: requests row,
  "Ranked by countries" leaderboard (own row pinned + amber-ringed), friend list,
  empty state.
- `Passport/Friends/FriendAvatar.swift` — initial-circle avatar (list, leaderboard,
  map switcher, request card).
- `Map/WhoseMapSheet.swift`, `Suitcase/TravelerPickerSheet.swift`.
- Reward variants `Reward.Kind.friendAdded` (`heart-handshake`) and
  `.firstTripTogether` (`circle-check`, same family as Trip complete) +
  `RewardEngine.friendAdded` / `.firstTripTogether`.

**Updated screens**
- `PassportTabView` — a **You / Friends** `SegmentedToggle` under the existing
  Trips/Passport one, in Passport mode only. Friends shows the "In total" stat
  above `FriendsListView`. Pro-gated: tapping Friends while Free → `.friends`
  upsell.
- `MapTabView` — "Whose map?" pill (top-left), shown only when ≥1 friend shares
  their passport. Selecting a friend swaps the `visited:` set the map renders and
  the pill becomes "Viewing <Name>'s map" with a tap-to-return.
- `TripDetailView` — a **Travelers** section (avatars + remove) with an
  "Add a traveler" dashed row → `TravelerPickerSheet`; Pro-gated via the existing
  `.addTraveler` upsell (`PackingGate.canAddTraveler`).
- `SettingsView` — "Friends can see my passport" row in Preferences. Toggle when
  Pro; a "Pro" nav row that opens the `.friends` upsell otherwise. Off by default.
- `Entitlements` — `UpsellMoment.friends`, `PlanLimits.friendsAllowed`,
  `PackingGate.canUseFriends`; `UpsellSheet` copy for `.friends`.
- `Friend.self` registered in the model container (`SuiteApp`, `SampleData`,
  `SettingsView.deleteAccount`).

## Data model — `Friend` (`Models/Friend.swift`)

Local SwiftData `@Model`. **No CloudKit / CKShare wiring** — Ivan said to ignore
that blocker. `FriendsService.addByCode` records a local pending row; the friend's
passport figures (`countryCodes`, `cityCount`, `sharedTrips`) are a **snapshot**
on the record, demo-seeded today, meant to refresh from the friend's shared copy
once sync ships. `sharesPassport` is the per-relationship visibility opt-in
(off by default). Your own invite code lives on `UserSettings.myShareCode`;
`UserSettings.friendsCanSeePassport` backs the settings toggle.

## Assumptions made (no handoff to check against)

1. **Passport headline stat** — the addendum's "estimated Global rank percentile"
   does not exist in the app. Friends rank sits alongside the real headline
   (`world %` / country count). No percentile stat was built.
2. **Notification center** — none exists. The friend-request card lives in a
   "Requests · N" row above the friend list in Passport → Friends.
3. **Stamp grid** — Passport had no stamp/badge grid component; `FriendProfileView`
   introduces a flag+ISO `LazyVGrid`. Not back-ported to the Passport tab.
4. **Leaderboard metric** — ranked by country count (not world %); both shown on
   friend-list rows.
5. **Map control** — chose the "Whose map?" button + sheet over an avatar strip
   (scales past ~4 friends).
6. **Share code** — 8 chars, ambiguity-free alphabet; QR encodes
   `https://suite.app/f/<code>` (placeholder host, no backend). The text code is a
   display convenience, not resolvable without the sync layer.
7. **Travelers step** — there was no existing travelers UI to "update"; a Travelers
   section was added to `TripDetailView`.
8. All colours / type / spacing / radii pulled from `Theme` tokens and the
   nearest existing component.

## Dev args

`-passportFriends` (open Friends segment), `-seedFriends` (2 sharing friends, 1
private, 1 incoming request), `-screen addFriends|friendProfile|friendProfileLocked|friendRequest`,
`-screen reward5|reward6`.

## Not done (still genuinely blocked)

iCloud sync + CKShare, real friend-to-friend connection, contacts discovery
(explicitly a v1.1 fast-follow), first-trip-together reward auto-trigger wiring.
