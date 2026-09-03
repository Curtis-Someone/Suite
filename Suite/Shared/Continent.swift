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

    /// Countries in this continent (design denominators).
    var totalCountries: Int {
        switch self {
        case .africa:       54
        case .asia:         50
        case .europe:       51
        case .northAmerica: 23
        case .southAmerica: 12
        case .oceania:      14
        }
    }

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
