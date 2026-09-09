import SwiftUI
import SwiftData

/// Suitcase tab — empty state, or the Upcoming / Past trip list.
struct SuitcaseTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    private let entitlements = Entitlements.shared
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @State private var showingBuilder = false
    @State private var showingProfile = false
    @State private var showingSearch = false
    @State private var upsell: UpsellMoment?
    @State private var path = NavigationPath()
    @State private var didApplyDevArgs = false

    private var upcoming: [Trip] { trips.filter { !$0.isArchived && $0.status != .past } }
    private var past: [Trip] { trips.visibleArchive(isPro: entitlements.isPro) }

    /// True once a Free user has hit the active-trip cap — the add-card then
    /// shows its locked (Pro) variant instead of the plain "New trip" prompt.
    private var tripLimitReached: Bool {
        if case .blocked = PackingGate.canCreateTrip(existingTrips: trips, isPro: entitlements.isPro) {
            return true
        }
        return false
    }

    /// Free tier caps active trips. Suitcases are added later, from the trip.
    private func newTripTapped() {
        switch PackingGate.canCreateTrip(existingTrips: trips, isPro: entitlements.isPro) {
        case .allowed:            showingBuilder = true
        case .blocked(let reason): upsell = reason
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                Theme.Palette.surface.ignoresSafeArea()

                if trips.isEmpty { emptyState } else { list }

                // Once the list has a few trips the dashed add-card scrolls away,
                // so the FAB takes over.
                if !trips.isEmpty && upcoming.count > 2 {
                    Button { newTripTapped() } label: {
                        SuiteIconView(icon: .plus, size: 24, color: Theme.Palette.onAccent)
                            .frame(width: 56, height: 56)
                            .background(Theme.Palette.accent, in: Circle())
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                    }
                    .accessibilityLabel("New trip")
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(for: Trip.self) { TripDetailView(trip: $0) }
            .navigationDestination(for: Suitcase.self) { PackingChecklistView(suitcase: $0) }
        }
        .fullScreenCover(isPresented: $showingBuilder) {
            NewTripFlow { newTrip in path.append(newTrip) }
        }
        .sheet(isPresented: $showingSearch) { SearchView() }
        .sheet(isPresented: $showingProfile) { ProfileView() }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .task { applyDevArgs() }
    }

    /// Dev: `-seedTrips`, `-openTrip <upcoming|past>` (trip detail),
    /// `-openChecklist <upcoming|past>` (its first bag's checklist), `-openBuilder`.
    private func applyDevArgs() {
        guard !didApplyDevArgs else { return }
        didApplyDevArgs = true
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-seedTrips") && trips.isEmpty {
            SampleData.seedSuitcaseDemo(into: context)
        }
        if args.contains("-seedOne") && trips.isEmpty {
            SampleData.seedOneTrip(into: context)
        }
        if args.contains("-openProfile") { showingProfile = true }

        func target(_ key: String) -> Trip? {
            guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
            switch args[i + 1] {
            case "past":  return past.first
            case "empty": return upcoming.first { $0.suitcases.isEmpty }
            default:      return upcoming.first
            }
        }
        if args.contains("-openBuilder") {
            showingBuilder = true
        } else if let trip = target("-openTrip") {
            DispatchQueue.main.async { path.append(trip) }
        } else if let trip = target("-openChecklist") {
            DispatchQueue.main.async {
                path.append(trip)
                if let bag = trip.suitcases.first { path.append(bag) }
            }
        }
    }

    // MARK: Header

    private var topBar: some View {
        HStack(spacing: 18) {
            Wordmark(size: 26)
            Spacer()
            Button { showingSearch = true } label: {
                SuiteIconView(icon: .search, size: 24, color: Theme.Palette.textBody)
            }
            .accessibilityLabel("Search")
            Button { showingProfile = true } label: {
                SuiteIconView(icon: .user, size: 28, color: Theme.Palette.textBody)
            }
            .accessibilityLabel("Profile")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: Populated

    /// While the list is still sparse, keep the hero banner and a dashed
    /// add-card so a one-trip screen reads full instead of empty.
    private var isSparse: Bool { upcoming.count <= 1 }

    private var list: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isSparse {
                        heroCard.padding(.bottom, 4)
                    } else if let next = upcoming.first {
                        nextTripHero(next).padding(.bottom, 4)
                    }
                    if !upcoming.isEmpty {
                        KickerLabel("Upcoming")
                        ForEach(upcoming) { trip in link(trip) }
                    }
                    if upcoming.count <= 2 {
                        if tripLimitReached { lockedAddCard } else { addCard }
                    }
                    if !past.isEmpty {
                        KickerLabel("Past").padding(.top, 6)
                        ForEach(past) { trip in link(trip) }
                    }
                    if isSparse {
                        packingTip.padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 120)   // clear the floating nav pill
            }
        }
    }

    private func link(_ trip: Trip) -> some View {
        NavigationLink(value: trip) { TripCardView(trip: trip) }
            .buttonStyle(.suitePress)
    }

    private var addCard: some View {
        Button { newTripTapped() } label: {
            HStack(spacing: 10) {
                SuiteIconView(icon: .plus, size: 18, color: Theme.Palette.textSecondary)
                Text("New trip")
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(Theme.Palette.border)
            )
        }
        .buttonStyle(.plain)
    }

    /// Same footprint as `addCard`, but once the Free trip cap is hit the "New
    /// trip" affordance reads as Pro-locked: solid amber-tint fill, a padlock
    /// where the "+" was, and a PRO tag. Still tappable — it opens the upsell.
    private var lockedAddCard: some View {
        Button { newTripTapped() } label: {
            HStack(spacing: 12) {
                LucideIcon(name: "lock", size: 18, color: Theme.Palette.onAccent)
                    .frame(width: 36, height: 36)
                    .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock more trips")
                        .font(.archivo(15, .semibold))
                        .foregroundStyle(Theme.Palette.textHeading)
                    Text("Free keeps two trips going at once")
                        .font(.archivo(12))
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                Spacer(minLength: 8)
                Text("PRO")
                    .font(.jetBrainsMono(11, .bold))
                    .foregroundStyle(Theme.Palette.accent)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Theme.Palette.accent.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .strokeBorder(Theme.Palette.accent.opacity(0.35))
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New trip, Pro")
        .accessibilityHint("The Free plan is limited to two active trips")
    }

    private var packingTip: some View {
        HStack(spacing: 12) {
            LucideIcon(name: "sparkles", size: 20, color: Theme.Palette.accent)
                .frame(width: 40, height: 40)
                .background(Theme.Palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            VStack(alignment: .leading, spacing: 3) {
                Text("Pack a little each day")
                    .font(.archivo(14, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("Suite fills the checklist from your trip type and the weather — just tick things off.")
                    .font(.archivo(12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 0) {
            topBar

            heroCard
                .padding(.horizontal, 24)
                .padding(.top, 18)

            Spacer()

            emptySuitcaseArt
                .frame(width: 220, height: 220)
            Text("No trips yet")
                .font(.archivo(17, .medium))
                .foregroundStyle(Theme.Palette.textHeading)
                .padding(.top, 4)
            Text("Plan a trip and Suite keeps its bags\nand checklists together.")
                .font(.Suite.bodyS)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textTertiary)
                .padding(.top, 8)

            Spacer()

            SuiteButton(title: "New trip", showsLeadingPlus: true) { newTripTapped() }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        // This screen's NavigationStack doesn't take the shell's bottom safe-area
        // inset, so clear the floating nav pill by hand — 96 + the button's own
        // 24 matches the 120pt the populated list and the Passport scroll use.
        .padding(.bottom, 96)
    }

    /// The art is dark line-work on white. On the light surface `.multiply` drops
    /// the white and keeps the linework; on the dark surface that same blend
    /// collapses to near-black, so there we invert to light lines and `.screen`
    /// the (now dark) ground away, landing on a soft light grey.
    @ViewBuilder
    private var emptySuitcaseArt: some View {
        if colorScheme == .dark {
            Image("SuitcaseOpen")
                .resizable().scaledToFit()
                .colorInvert()
                .blendMode(.screen)
                .opacity(0.55)
        } else {
            Image("SuitcaseOpen")
                .resizable().scaledToFit()
                .blendMode(.multiply)
                .opacity(0.85)
        }
    }

    /// Amber card, luminosity-blended suitcase photo, dark bottom-up gradient,
    /// kicker + headline — traced from the S1 artboard.
    private var heroCard: some View {
        ZStack {
            Theme.Palette.accent
            Image("SuitcaseClosed")
                .resizable()
                .scaledToFill()
                .contrast(1.05)
                .blendMode(.luminosity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .clipped()
        .compositingGroup()
        .overlay(
            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your suitcase")
                    .font(.jetBrainsMono(10)).tracking(1.4).textCase(.uppercase)
                    .foregroundStyle(Theme.Palette.accent)
                Text("Pack once, forget nothing")
                    .font(.archivo(21, .bold)).tracking(21 * -0.02)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    /// Slimmer sibling of `heroCard` for the populated list, where the full hero
    /// has scrolled out of the layout. Same amber + luminosity-photo treatment,
    /// but focused on the soonest trip: name, countdown, dates · country, and a
    /// packing-progress bar. Taps through to that trip.
    private func nextTripHero(_ trip: Trip) -> some View {
        NavigationLink(value: trip) {
            ZStack {
                Theme.Palette.accent
                Image("SuitcaseClosed")
                    .resizable()
                    .scaledToFill()
                    .contrast(1.05)
                    .blendMode(.luminosity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 118)
            .clipped()
            .compositingGroup()
            .overlay(
                LinearGradient(colors: [.clear, .black.opacity(0.85)],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("Next trip")
                            .foregroundStyle(Theme.Palette.accent)
                        Text("· \(nextTripCountdown(trip))")
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .font(.jetBrainsMono(10)).tracking(1.4).textCase(.uppercase)

                    Text(trip.name)
                        .font(.archivo(19, .bold)).tracking(19 * -0.02)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("\(PackingChecklistView.dateRange(trip)) · \(trip.destinationCountry)")
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer(minLength: 8)
                        Text(nextTripProgressLabel(trip))
                            .foregroundStyle(.white)
                    }
                    .font(.jetBrainsMono(11, .medium))
                    .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.25))
                            Capsule().fill(.white)
                                .frame(width: max(0, min(1, nextTripProgress(trip))) * geo.size.width)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.suitePress)
    }

    private func nextTripProgress(_ trip: Trip) -> Double {
        let bags = trip.suitcases
        guard !bags.isEmpty else { return 0 }
        return bags.map(\.progress).reduce(0, +) / Double(bags.count)
    }

    private func nextTripProgressLabel(_ trip: Trip) -> String {
        guard !trip.suitcases.isEmpty else { return "no bags yet" }
        return "\(Int((nextTripProgress(trip) * 100).rounded()))% packed"
    }

    private func nextTripCountdown(_ trip: Trip) -> String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: trip.startDate).day ?? 0
        if days > 1 { return "in \(days)d" }
        if days == 1 { return "tomorrow" }
        if days == 0 { return "today" }
        return "under way"
    }
}
