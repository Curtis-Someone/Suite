import Foundation

struct Country: Identifiable, Hashable {
    let code: String   // ISO 3166-1 alpha-2
    let name: String
    var id: String { code }
}

/// Country list for the home-country picker. Built from the system's ISO region
/// data — no bundled data file. Continent grouping (needed for the Passport tab)
/// comes in batch 6.
enum Countries {
    static let all: [Country] = {
        let english = Locale(identifier: "en_US")
        return Locale.Region.isoRegions
            .filter { $0.identifier.count == 2 }
            .compactMap { region in
                english.localizedString(forRegionCode: region.identifier)
                    .map { Country(code: region.identifier, name: $0) }
            }
            .sorted { $0.name < $1.name }
    }()

    /// Codes floated to the top of the unfiltered picker — the countries this
    /// audience most often calls home. Listed in the order they should appear.
    static let popularCodes = ["ES", "PT", "FR", "DE", "IT", "IE", "GB", "NL", "BE", "CH"]

    /// `all`, but with the popular countries first (in `popularCodes` order) and
    /// everyone else alphabetically after. Used when no search query is active.
    static let prioritized: [Country] = {
        let popular = popularCodes.compactMap { code in all.first { $0.code == code } }
        let rest = all.filter { !popularCodes.contains($0.code) }
        return popular + rest
    }()

    static func name(for code: String) -> String {
        all.first { $0.code == code }?.name ?? code
    }
}
