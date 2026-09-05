import SwiftUI
import SwiftData

/// M2 · Country sheet — presented over the map. Flag + name, Visited / Want-to-go
/// toggles, and a Cities / Regions list with per-row quick actions.
struct CountryDetailView: View {
    let iso: String

    @Environment(\.modelContext) private var context
    @Query private var allVisits: [VisitedPlace]
    @Query private var allWishes: [WishlistPlace]

    @State private var tab: Tab = .cities
    private enum Tab { case cities, regions }

    private var code: String { iso.uppercased() }
    private var country: Country? { Countries.all.first { $0.code == code } }

    private var visits: [VisitedPlace] { allVisits.filter { $0.countryCode.uppercased() == code } }
    private var wishes: [WishlistPlace] { allWishes.filter { $0.countryCode.uppercased() == code } }

    private var countryVisited: Bool { !visits.isEmpty }
    private var countryWanted: Bool { wishes.contains { $0.cityName.isEmpty } }
    private var visitedCities: Set<String> { Set(visits.map(\.cityName).filter { !$0.isEmpty }) }
    private var wantedCities: Set<String> { Set(wishes.map(\.cityName).filter { !$0.isEmpty }) }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 12) {
                bigToggle("Visited", icon: .flag, on: countryVisited) { toggleVisited() }
                bigToggle("Want to go", icon: .heart, on: countryWanted) { toggleWanted() }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            tabs.padding(.top, 24)
            Rectangle().fill(Theme.Palette.divider).frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if tab == .cities {
                        let cities = WorldCities.cities(for: code)
                        if cities.isEmpty { emptyRow("No cities listed for this country.") }
                        ForEach(cities) { cityRow($0) }
                    } else {
                        let regions = WorldCities.regions(for: code)
                        if regions.isEmpty { emptyRow("No regions listed for this country.") }
                        ForEach(regions, id: \.self) { regionRow($0) }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Theme.Palette.ground)
        .presentationDetents([.height(430), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.Palette.ground)
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 14) {
            Text(country?.flag ?? "")
                .font(.system(size: 30))
                .frame(width: 52, height: 40)
                .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: 10))
            Text(country?.name ?? iso)
                .font(.Suite.titleL).tracking(27 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    // MARK: tabs

    private var tabs: some View {
        HStack(spacing: 0) {
            tabButton("Cities", .cities)
            tabButton("Regions", .regions)
        }
        .padding(.horizontal, 24)
    }

    private func tabButton(_ title: String, _ value: Tab) -> some View {
        let active = tab == value
        return Button { tab = value } label: {
            VStack(spacing: 10) {
                Text(title)
                    .font(.archivo(15, active ? .semibold : .medium))
                    .foregroundStyle(active ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)
                Rectangle()
                    .fill(active ? Theme.Palette.accent : .clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.suitePress)
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: rows

    private func cityRow(_ city: WorldCities.City) -> some View {
        row(
            icon: { LucideIcon(name: "building-2", size: 18, color: Theme.Palette.textSecondary) },
            title: city.name,
            subtitle: city.region,
            visited: visitedCities.contains(city.name),
            wanted: wantedCities.contains(city.name),
            toggleVisited: { toggleCityVisited(city.name) },
            toggleWanted: { toggleCityWanted(city.name) }
        )
    }

    private func regionRow(_ name: String) -> some View {
        HStack(spacing: 14) {
            SuiteIconView(icon: .mapPin, size: 16, color: Theme.Palette.textSecondary)
            Text(name).font(.archivo(15, .medium)).foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(height: 58)
    }

    private func row<Icon: View>(
        @ViewBuilder icon: () -> Icon,
        title: String, subtitle: String,
        visited: Bool, wanted: Bool,
        toggleVisited: @escaping () -> Void, toggleWanted: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            icon().frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.archivo(15, .semibold)).foregroundStyle(Theme.Palette.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.archivo(12)).foregroundStyle(Theme.Palette.textTertiary)
                }
            }
            Spacer()
            quickToggle(icon: .flag, on: visited, action: toggleVisited)
            quickToggle(icon: .heart, on: wanted, action: toggleWanted)
        }
        .padding(.horizontal, 24)
        .frame(height: 62)
    }

    private func quickToggle(icon: SuiteIcon, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SuiteIconView(icon: icon, size: 15, color: on ? Theme.Palette.onAccent : Theme.Palette.textSecondary)
                .frame(width: 38, height: 38)
                .background(on ? Theme.Palette.accent : Theme.Palette.fill,
                           in: RoundedRectangle(cornerRadius: 11))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.suitePress)
        .accessibilityLabel(icon == .flag ? "Visited" : "Want to go")
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func bigToggle(_ title: String, icon: SuiteIcon, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                SuiteIconView(icon: icon, size: 17,
                              color: on ? Theme.Palette.onAccent : Theme.Palette.textPrimary)
                Text(title)
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(on ? Theme.Palette.onAccent : Theme.Palette.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(on ? Theme.Palette.accent : Theme.Palette.surfaceSunken, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Palette.border, lineWidth: on ? 0 : 1))
        }
        .buttonStyle(.suitePress)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.Suite.bodyS)
            .foregroundStyle(Theme.Palette.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
    }

    // MARK: mutations

    private func toggleVisited() {
        if countryVisited {
            for v in visits { context.delete(v) }
            try? context.save()
        } else {
            context.insert(VisitedPlace(countryName: country?.name ?? iso, countryCode: code))
            try? context.save()
            RewardEngine.countryAdded(
                code: code,
                visitsAfter: (try? context.fetch(FetchDescriptor<VisitedPlace>())) ?? [])
        }
    }

    private func toggleWanted() {
        if let existing = wishes.first(where: { $0.cityName.isEmpty }) {
            context.delete(existing)
        } else {
            context.insert(WishlistPlace(countryName: country?.name ?? iso, countryCode: code))
        }
        try? context.save()
    }

    private func toggleCityVisited(_ city: String) {
        if let existing = visits.first(where: { $0.cityName == city }) {
            context.delete(existing)
            try? context.save()
        } else {
            let wasNewCountry = visits.isEmpty
            context.insert(VisitedPlace(countryName: country?.name ?? iso, countryCode: code, cityName: city))
            try? context.save()
            if wasNewCountry {
                RewardEngine.countryAdded(
                    code: code,
                    visitsAfter: (try? context.fetch(FetchDescriptor<VisitedPlace>())) ?? [])
            }
        }
    }

    private func toggleCityWanted(_ city: String) {
        if let existing = wishes.first(where: { $0.cityName == city }) {
            context.delete(existing)
        } else {
            context.insert(WishlistPlace(countryName: country?.name ?? iso, countryCode: code, cityName: city))
        }
        try? context.save()
    }
}
