import Foundation

/// The six continents the Passport breaks countries into. Totals match the
/// design's denominators (curated UN-country counts, Americas split N/S).
enum Continent: String, CaseIterable, Identifiable {
    case africa, asia, europe, northAmerica, southAmerica, oceania

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .africa:       "Africa"
        case .asia:         "Asia"
        case .europe:       "Europe"
        case .northAmerica: "N. America"
        case .southAmerica: "S. America"
        case .oceania:      "Oceania"
        }
    }

    /// Countries in this continent — the count of curated UN sovereign states
    /// that resolve here (see `Countries.continentCounts`). Used as the Passport
    /// denominator, so a visited count can never exceed it.
    var totalCountries: Int { Countries.continentCounts[self] ?? 0 }

    /// Display order on the Passport tab.
    var sortRank: Int {
        switch self {
        case .europe: 0
        case .asia: 1
        case .northAmerica: 2
        case .africa: 3
        case .southAmerica: 4
        case .oceania: 5
        }
    }
}
