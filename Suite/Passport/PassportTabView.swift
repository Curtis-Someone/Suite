import SwiftUI
import SwiftData

/// 11 · Passport tab — travel stats over `VisitedPlace`, plus a Trips log.
struct PassportTabView: View {
    @Environment(\.modelContext) private var context
    private let entitlements = Entitlements.shared
    @Query private var visits: [VisitedPlace]
    @Query(sort: \Trip.endDate, order: .reverse) private var allTrips: [Trip]
    @State private var didSeed = false

    @State private var mode: Mode = ProcessInfo.processInfo.arguments.contains("-passportTrips") ? .trips : .passport
    @State private var year: Int? = nil          // nil = all time
    @State private var showingAdd = ProcessInfo.processInfo.arguments.contains("-openAddVisit")
    @State private var showingBuilder = false
    @State private var path = NavigationPath()

    enum Mode: Hashable { case trips, passport }
    private struct CountryList: Hashable {}

    private var filteredVisits: [VisitedPlace] {
        guard let year else { return visits }
        return visits.filter { Calendar.current.component(.year, from: $0.firstVisitedDate) == year }
    }
    private var pastTrips: [Trip] {
        let list = allTrips.visibleArchive(isPro: entitlements.isPro)
        guard let year else { return list }
        return list.filter { Calendar.current.component(.year, from: $0.endDate) == year }
    }
    private var years: [Int] {
        Set(visits.map { Calendar.current.component(.year, from: $0.firstVisitedDate) })
            .sorted(by: >)
    }
    private var stats: PassportStats { PassportStats(visits: filteredVisits) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                Theme.Palette.surface.ignoresSafeArea()
                watermark
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(spacing: 14) {
                            switch mode {
                            case .passport: passportContent
                            case .trips:    TripsListView(trips: pastTrips) { showingBuilder = true }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 120)   // clear the floating nav pill
                    }
                }
            }
            .navigationDestination(for: Continent.self) { ContinentDetailView(continent: $0) }
            .navigationDestination(for: CountryList.self) { _ in CountryListView() }
            .navigationDestination(for: Trip.self) { PackingChecklistView(trip: $0) }
        }
        .sheet(isPresented: $showingAdd) { AddVisitView() }
        .fullScreenCover(isPresented: $showingBuilder) { NewSuitcaseFlow { _ in } }
        .task {
            guard !didSeed else { return }
            didSeed = true
            if ProcessInfo.processInfo.arguments.contains("-seedVisits") && visits.count < 3 {
                SampleData.seedVisitsDemo(into: context)
            }
        }
    }

    // MARK: Chrome

    private var watermark: some View {
        Image("WorldMap")
            .resizable().scaledToFill()
            .frame(height: 190)
            .opacity(0.12)
            .frame(maxWidth: .infinity)
            .clipped()
            .allowsHitTesting(false)
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Text("Passport")
                    .font(.Suite.titleL).tracking(27 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button { showingAdd = true } label: {
                    SuiteIconView(icon: .plus, size: 20, color: Theme.Palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                .accessibilityLabel("Add a place you've visited")
            }

            SegmentedToggle(
                options: [(Mode.trips, "Trips"), (Mode.passport, "Passport")],
                selection: $mode
            )

            if mode == .passport && !years.isEmpty {
                HStack(spacing: 8) {
                    FilterChip(title: "All time", isActive: year == nil) { year = nil }
                    ForEach(years, id: \.self) { y in
                        FilterChip(title: "\(y)", isActive: year == y) { year = y }
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: Passport content

    @ViewBuilder
    private var passportContent: some View {
        inTotalCard
        // Until there's more than the seeded home country, invite rather than
        // show a mostly-empty breakdown.
        if stats.countryCount <= 1 {
            startPromptCard
        } else {
            continentsCard
            myCountriesCard
        }
    }

    private var inTotalCard: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("In total").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                HStack(alignment: .bottom) {
                    StatColumn(value: "\(stats.countryCount)", unit: " / 195", caption: "countries")
                    Spacer(minLength: 12)
                    StatColumn(value: "\(Int((stats.worldPercent * 100).rounded()))", unit: "%",
                               caption: "of the world", alignment: .trailing)
                }
                SuiteProgressBar(value: stats.worldPercent)
                Text("Based on 195 UN countries")
                    .font(.Suite.labelS)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var startPromptCard: some View {
        SuiteCard(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                LucideIcon(name: "globe", size: 24, color: Theme.Palette.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.Palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                Text(stats.countryCount == 1 ? "One stamp so far" : "Your passport is empty")
                    .font(.Suite.titleS).tracking(22 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(stats.countryCount == 1
                     ? "Your home country's already on the map. Add everywhere else you've been and your continents and world % fill in."
                     : "Add the countries you've been to and Suite builds your continents, world % and travel log around them.")
                    .font(.Suite.bodyS)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Theme.Palette.textSecondary)
                SuiteButton(title: "Add places", showsLeadingPlus: true) { showingAdd = true }
                    .padding(.top, 4)
            }
        }
    }

    private var continentsCard: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 13) {
                Text("My continents").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                ForEach(stats.perContinent, id: \.continent) { row in
                    Button { path.append(row.continent) } label: {
                        continentRow(row.continent, visited: row.visited)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var myCountriesCard: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 13) {
                Button { path.append(CountryList()) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My countries").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                            Text("and non-UN territories").font(.archivo(11)).foregroundStyle(Theme.Palette.textTertiary)
                        }
                        Spacer()
                        SuiteIconView(icon: .chevronRight, size: 16)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.suitePress)
                .accessibilityLabel("My countries and territories")
                .accessibilityAddTraits(.isButton)

                ForEach(Array(stats.visitedCountries.prefix(3)), id: \.code) { country in
                    HStack(spacing: 12) {
                        Text(country.flag).font(.system(size: 20)).frame(width: 30, height: 21)
                        Text(country.name).font(.archivo(14, .medium)).foregroundStyle(Theme.Palette.textHeading)
                    }
                }
                if stats.countryCount > 3 {
                    Text("+ \(stats.countryCount - 3) more")
                        .font(.archivo(13))
                        .foregroundStyle(Theme.Palette.textTertiary)
                }
            }
        }
    }

    private func continentRow(_ continent: Continent, visited: Int) -> some View {
        HStack(spacing: 10) {
            Text(continent.displayName)
                .font(.archivo(13, .medium))
                .foregroundStyle(visited > 0 ? Theme.Palette.textHeading : Theme.Palette.textSecondary)
                .frame(width: 78, alignment: .leading)
            SuiteProgressBar(value: Double(visited) / Double(continent.totalCountries), height: 8)
            Text("\(visited)/\(continent.totalCountries)")
                .font(.Suite.data)
                .foregroundStyle(Theme.Palette.textBody)
                .frame(width: 40, alignment: .trailing)
            Text("\(Int((Double(visited) / Double(continent.totalCountries) * 100).rounded()))%")
                .font(.Suite.data)
                .foregroundStyle(Theme.Palette.textTertiary)
                .frame(width: 34, alignment: .trailing)
        }
    }
}
