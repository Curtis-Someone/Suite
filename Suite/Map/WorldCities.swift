import Foundation

/// Bundled major-cities / regions lookup, keyed by ISO-3166-1 alpha-2.
/// Source: GeoNames `cities15000` (top ~12 by population) + `admin1CodesASCII`.
enum WorldCities {
    struct City: Identifiable, Hashable {
        let name: String
        let region: String
        var id: String { name }
    }

    static func cities(for iso: String) -> [City] { citiesByCountry[iso.uppercased()] ?? [] }
    static func regions(for iso: String) -> [String] { regionsByCountry[iso.uppercased()] ?? [] }

    /// Flat name-prefix search across every bundled city. `(city, ISO2)`.
    static func search(_ query: String, limit: Int = 8) -> [(name: String, iso: String)] {
        guard query.count >= 2 else { return [] }
        var out: [(String, String)] = []
        for (iso, list) in citiesByCountry {
            for c in list where c.name.localizedCaseInsensitiveContains(query) {
                out.append((c.name, iso))
                if out.count >= limit * 3 { break }
            }
        }
        return out
            .sorted { $0.0.count < $1.0.count }
            .prefix(limit)
            .map { (name: $0.0, iso: $0.1) }
    }

    private static let citiesByCountry: [String: [City]] = {
        struct Raw: Decodable { let n: String; let r: String? }
        guard let url = Bundle.main.url(forResource: "world-cities.min", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: [Raw]].self, from: data)
        else { return [:] }
        return raw.mapValues { list in list.map { City(name: $0.n, region: $0.r ?? "") } }
    }()

    private static let regionsByCountry: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "world-regions.min", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return raw
    }()
}
