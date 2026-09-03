import Foundation

/// Everything the Passport tab shows, derived from the `VisitedPlace` rows.
struct PassportStats {
    static let unCountryTotal = 195

    let countryCodes: Set<String>
    let cityCount: Int
    let perContinent: [(continent: Continent, visited: Int)]

    init(visits: [VisitedPlace]) {
        let codes = Set(visits.map { $0.countryCode.uppercased() }.filter { !$0.isEmpty })
        countryCodes = codes
        cityCount = Set(visits.map(\.cityName).filter { !$0.isEmpty }).count
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
