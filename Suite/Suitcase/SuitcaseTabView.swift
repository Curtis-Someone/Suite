import SwiftUI
import SwiftData

/// Suitcase tab — empty state, or the Upcoming / Past trip list.
struct SuitcaseTabView: View {
    @Environment(\.modelContext) private var context
    private let entitlements = Entitlements.shared
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @State private var showingBuilder = false
    @State private var showingProfile = false
    @State private var showingSearch = false
    @State private var upsell: UpsellMoment?
    @State private var path: [Trip] = []
    @State private var didApplyDevArgs = false

    private var upcoming: [Trip] { trips.filter { !$0.isArchived && $0.status != .past } }
    private var past: [Trip] { trips.visibleArchive(isPro: entitlements.isPro) }

    /// Free tier caps active trips — creating a suitcase creates a trip here.
    private func newSuitcaseTapped() {
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
                    Button { newSuitcaseTapped() } label: {
                        SuiteIconView(icon: .plus, size: 24, color: Theme.Palette.onAccent)
                            .frame(width: 56, height: 56)
                            .background(Theme.Palette.accent, in: Circle())
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                    }
                    .accessibilityLabel("New suitcase")
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(for: Trip.self) { PackingChecklistView(trip: $0) }
        }
        .fullScreenCover(isPresented: $showingBuilder) {
            NewSuitcaseFlow { newTrip in path = [newTrip] }
        }
        .sheet(isPresented: $showingSearch) { SearchView() }
        .sheet(isPresented: $showingProfile) { ProfileView() }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .task { applyDevArgs() }
    }

    /// Dev: `-seedTrips`, `-openChecklist <upcoming|past>`, `-openBuilder`.
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
        if args.contains("-openBuilder") {
            showingBuilder = true
        } else if let i = args.firstIndex(of: "-openChecklist"), i + 1 < args.count {
            DispatchQueue.main.async {
                let target = args[i + 1] == "past" ? past.first : upcoming.first
                if let target { path = [target] }
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Search")
            Button { showingProfile = true } label: {
                SuiteIconView(icon: .user, size: 28, color: Theme.Palette.textBody)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
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
                    }
                    if !upcoming.isEmpty {
                        KickerLabel("Upcoming")
                        ForEach(upcoming) { trip in link(trip) }
                    }
                    if upcoming.count <= 2 {
                        addCard
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
            .accessibilityHint("Opens the packing checklist")
    }

    private var addCard: some View {
        Button { newSuitcaseTapped() } label: {
            HStack(spacing: 10) {
                SuiteIconView(icon: .plus, size: 18, color: Theme.Palette.textSecondary)
                Text("New suitcase")
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(Theme.Palette.border)
            )
        }
        .buttonStyle(.suitePress)
    }

    private var packingTip: some View {
        HStack(spacing: 12) {
            LucideIcon(name: "sparkles", size: 20, color: Theme.Palette.accent)
                .frame(width: 40, height: 40)
                .background(Theme.Palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
        .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 0) {
            topBar

            heroCard
                .padding(.horizontal, 24)
                .padding(.top, 18)

            Spacer()

            Image("SuitcaseOpen")
                .resizable().scaledToFit()
                .frame(width: 220, height: 220)
                .blendMode(.multiply)
                .opacity(0.85)
            Text("Empty suitcase")
                .font(.archivo(17, .medium))
                .foregroundStyle(Theme.Palette.textHeading)
                .padding(.top, 4)
            Text("Start one and Suite will keep the\nchecklist for your next trip.")
                .font(.Suite.bodyS)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textTertiary)
                .padding(.top, 8)

            Spacer()

            SuiteButton(title: "New suitcase", showsLeadingPlus: true) { newSuitcaseTapped() }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        // This screen's NavigationStack doesn't take the shell's bottom safe-area
        // inset, so clear the floating nav pill by hand — 96 + the button's own
        // 24 matches the 120pt the populated list and the Passport scroll use.
        .padding(.bottom, 96)
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
