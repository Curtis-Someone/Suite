import SwiftUI
import SwiftData

/// G3 · Search — live-filtered across your trips, countries and cities.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var trips: [Trip]
    @Query private var visits: [VisitedPlace]

    @State private var query: String = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-searchQuery"), i + 1 < a.count { return a[i + 1] }
        return ""
    }()
    @FocusState private var focused: Bool

    private var visitedCountryCodes: Set<String> { Set(visits.map { $0.countryCode.uppercased() }) }
    private var visitedCityKeys: Set<String> {
        Set(visits.filter { !$0.cityName.isEmpty }.map { "\($0.countryCode.uppercased())|\($0.cityName)" })
    }

    private enum Result: Identifiable {
        case trip(Trip)
        case country(Country, visited: Bool)
        case city(name: String, iso: String, country: String, visited: Bool)

        var id: String {
            switch self {
            case .trip(let t): "trip-\(t.tripID)"
            case .country(let c, _): "country-\(c.code)"
            case .city(let n, let iso, _, _): "city-\(iso)-\(n)"
            }
        }
    }

    private var results: [Result] {
        guard query.count >= 2 else { return [] }
        let tripHits = trips
            .filter { $0.name.localizedCaseInsensitiveContains(query) || $0.destinationCountry.localizedCaseInsensitiveContains(query) }
            .map { Result.trip($0) }
        let countryHits = Countries.all
            .filter { $0.name.localizedCaseInsensitiveContains(query) }
            .prefix(8)
            .map { Result.country($0, visited: visitedCountryCodes.contains($0.code)) }
        let cityHits = WorldCities.search(query)
            .map { hit in
                Result.city(name: hit.name, iso: hit.iso,
                            country: Countries.name(for: hit.iso),
                            visited: visitedCityKeys.contains("\(hit.iso)|\(hit.name)"))
            }
        return tripHits + countryHits + cityHits
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    SuiteIconView(icon: .search, size: 18, color: Theme.Palette.textPrimary)
                    TextField("Search trips, countries, cities", text: $query)
                        .font(.Suite.body)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .tint(Theme.Palette.accent)
                }
                .padding(.horizontal, 18)
                .frame(height: 50)
                .background(Theme.Palette.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.Palette.textPrimary, lineWidth: 1))

                Button("Cancel") { dismiss() }
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if !query.isEmpty {
                HStack {
                    KickerLabel("\(results.count) result\(results.count == 1 ? "" : "s")")
                    Spacer()
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 10)
            }

            if query.count >= 2 && results.isEmpty {
                Spacer()
                Text("Nothing matches “\(query)”.")
                    .font(.Suite.bodyS)
                    .foregroundStyle(Theme.Palette.textTertiary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(results) { row($0) }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .onAppear { focused = true }
    }

    @ViewBuilder
    private func row(_ result: Result) -> some View {
        switch result {
        case .trip(let trip):
            resultRow(
                leading: AnyView(
                    LucideIcon(name: trip.iconName, size: 18, color: Theme.Palette.onAccent)
                        .frame(width: 34, height: 24)
                        .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 5))),
                title: trip.name, subtitle: "Trip · \(trip.destinationCountry)")
        case .country(let country, let visited):
            resultRow(
                leading: AnyView(codeChip(country.code, on: visited)),
                title: country.name,
                subtitle: visited ? "Visited" : "Country",
                subtitleAccent: visited)
        case .city(let name, let iso, let country, let visited):
            resultRow(
                leading: AnyView(codeChip(iso, on: visited)),
                title: name,
                subtitle: visited ? "Visited" : "City · \(country)",
                subtitleAccent: visited)
        }
    }

    private func codeChip(_ code: String, on: Bool) -> some View {
        Text(code.uppercased())
            .font(.jetBrainsMono(10, .semibold))
            .foregroundStyle(on ? Theme.Palette.onAccent : Theme.Palette.textSecondary)
            .frame(width: 34, height: 24)
            .background(on ? Theme.Palette.accent : Theme.Palette.fillStrong,
                       in: RoundedRectangle(cornerRadius: 5))
    }

    private func resultRow(leading: AnyView, title: String, subtitle: String, subtitleAccent: Bool = false) -> some View {
        HStack(spacing: 14) {
            leading
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.archivo(15, .semibold)).foregroundStyle(Theme.Palette.textPrimary)
                Text(subtitle)
                    .font(subtitleAccent ? .jetBrainsMono(11) : .archivo(12))
                    .textCase(subtitleAccent ? .uppercase : nil)
                    .foregroundStyle(subtitleAccent ? Theme.Palette.accent : Theme.Palette.textTertiary)
            }
            Spacer()
            SuiteIconView(icon: .chevronRight, size: 16)
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
