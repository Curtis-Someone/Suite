import Foundation

/// Everything the Passport tab shows, derived from the `VisitedPlace` rows.
struct PassportStats {
    static let unCountryTotal = Countries.all.count   // 195

    let countryCodes: Set<String>
    let cityCount: Int
    let perContinent: [(continent: Continent, visited: Int)]

    init(visits: [VisitedPlace]) {
        // Only curated sovereign states count toward the "/195" stat — a stray
        // territory code (e.g. tapped on the map) must not push it over 100%.
        let codes = Set(visits.map { $0.countryCode.uppercased() }.filter { !$0.isEmpty })
            .intersection(Countries.codes)
        countryCodes = codes
        // Dedupe cities per country, not by bare name app-wide (QA M-17):
        // "San José, CR" and "San José, CY" are two cities.
        cityCount = Set(
            visits
                .filter { !$0.cityName.isEmpty }
                .map { "\($0.countryCode.uppercased())\u{1}\($0.cityName)" }
        ).count
        perContinent = Continent.allCases
            .sorted { $0.sortRank < $1.sortRank }
            .map { continent in
                (continent, codes.filter { Countries.continent(for: $0) == continent }.count)
            }
    }

    var countryCount: Int { countryCodes.count }
    var worldPercent: Double { Double(countryCount) / Double(Self.unCountryTotal) }

    /// Visited countries as `Country` values, name-sorted.
    var visitedCountries: [Country] {
        countryCodes
            .compactMap { code in Countries.all.first { $0.code == code } }
            .sorted { $0.name < $1.name }
    }
}
