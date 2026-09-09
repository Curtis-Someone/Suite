import Foundation

struct Country: Identifiable, Hashable {
    let code: String   // ISO 3166-1 alpha-2
    let name: String
    var id: String { code }

    /// Emoji flag for `code`, built from Unicode regional-indicator symbols
    /// (e.g. "ES" → 🇪🇸). Rendered by the OS, so it always matches the real flag
    /// and needs no bundled assets.
    var flag: String {
        code.unicodeScalars.reduce(into: "") { result, scalar in
            if let indicator = UnicodeScalar(0x1F1E6 + scalar.value - 0x41) {
                result.unicodeScalars.append(indicator)
            }
        }
    }
}

/// Country list for the home-country picker and every Passport count.
///
/// A curated list of the 195 UN-recognised sovereign states (193 members + the
/// Holy See and the State of Palestine). Deliberately NOT `Locale.Region.isoRegions`
/// — that returns ~250 entries including `EU`, `UN`, and dependent territories,
/// which let `worldPercent` exceed 100% and made "European Union" a pickable
/// home country (QA M-17).
enum Countries {
    /// (ISO 3166-1 alpha-2, English name). Kept sorted by name via `all`.
    private static let catalog: [(String, String)] = [
        ("AF", "Afghanistan"), ("AL", "Albania"), ("DZ", "Algeria"), ("AD", "Andorra"),
        ("AO", "Angola"), ("AG", "Antigua & Barbuda"), ("AR", "Argentina"), ("AM", "Armenia"),
        ("AU", "Australia"), ("AT", "Austria"), ("AZ", "Azerbaijan"), ("BS", "Bahamas"),
        ("BH", "Bahrain"), ("BD", "Bangladesh"), ("BB", "Barbados"), ("BY", "Belarus"),
        ("BE", "Belgium"), ("BZ", "Belize"), ("BJ", "Benin"), ("BT", "Bhutan"),
        ("BO", "Bolivia"), ("BA", "Bosnia & Herzegovina"), ("BW", "Botswana"), ("BR", "Brazil"),
        ("BN", "Brunei"), ("BG", "Bulgaria"), ("BF", "Burkina Faso"), ("BI", "Burundi"),
        ("CV", "Cabo Verde"), ("KH", "Cambodia"), ("CM", "Cameroon"), ("CA", "Canada"),
        ("CF", "Central African Republic"), ("TD", "Chad"), ("CL", "Chile"), ("CN", "China"),
        ("CO", "Colombia"), ("KM", "Comoros"), ("CG", "Congo - Brazzaville"),
        ("CD", "Congo - Kinshasa"), ("CR", "Costa Rica"), ("CI", "Côte d’Ivoire"),
        ("HR", "Croatia"), ("CU", "Cuba"), ("CY", "Cyprus"), ("CZ", "Czechia"),
        ("DK", "Denmark"), ("DJ", "Djibouti"), ("DM", "Dominica"), ("DO", "Dominican Republic"),
        ("EC", "Ecuador"), ("EG", "Egypt"), ("SV", "El Salvador"), ("GQ", "Equatorial Guinea"),
        ("ER", "Eritrea"), ("EE", "Estonia"), ("SZ", "Eswatini"), ("ET", "Ethiopia"),
        ("FJ", "Fiji"), ("FI", "Finland"), ("FR", "France"), ("GA", "Gabon"),
        ("GM", "Gambia"), ("GE", "Georgia"), ("DE", "Germany"), ("GH", "Ghana"),
        ("GR", "Greece"), ("GD", "Grenada"), ("GT", "Guatemala"), ("GN", "Guinea"),
        ("GW", "Guinea-Bissau"), ("GY", "Guyana"), ("HT", "Haiti"), ("HN", "Honduras"),
        ("HU", "Hungary"), ("IS", "Iceland"), ("IN", "India"), ("ID", "Indonesia"),
        ("IR", "Iran"), ("IQ", "Iraq"), ("IE", "Ireland"), ("IL", "Israel"),
        ("IT", "Italy"), ("JM", "Jamaica"), ("JP", "Japan"), ("JO", "Jordan"),
        ("KZ", "Kazakhstan"), ("KE", "Kenya"), ("KI", "Kiribati"), ("KW", "Kuwait"),
        ("KG", "Kyrgyzstan"), ("LA", "Laos"), ("LV", "Latvia"), ("LB", "Lebanon"),
        ("LS", "Lesotho"), ("LR", "Liberia"), ("LY", "Libya"), ("LI", "Liechtenstein"),
        ("LT", "Lithuania"), ("LU", "Luxembourg"), ("MG", "Madagascar"), ("MW", "Malawi"),
        ("MY", "Malaysia"), ("MV", "Maldives"), ("ML", "Mali"), ("MT", "Malta"),
        ("MH", "Marshall Islands"), ("MR", "Mauritania"), ("MU", "Mauritius"), ("MX", "Mexico"),
        ("FM", "Micronesia"), ("MD", "Moldova"), ("MC", "Monaco"), ("MN", "Mongolia"),
        ("ME", "Montenegro"), ("MA", "Morocco"), ("MZ", "Mozambique"), ("MM", "Myanmar (Burma)"),
        ("NA", "Namibia"), ("NR", "Nauru"), ("NP", "Nepal"), ("NL", "Netherlands"),
        ("NZ", "New Zealand"), ("NI", "Nicaragua"), ("NE", "Niger"), ("NG", "Nigeria"),
        ("KP", "North Korea"), ("MK", "North Macedonia"), ("NO", "Norway"), ("OM", "Oman"),
        ("PK", "Pakistan"), ("PW", "Palau"), ("PS", "Palestine"), ("PA", "Panama"),
        ("PG", "Papua New Guinea"), ("PY", "Paraguay"), ("PE", "Peru"), ("PH", "Philippines"),
        ("PL", "Poland"), ("PT", "Portugal"), ("QA", "Qatar"), ("RO", "Romania"),
        ("RU", "Russia"), ("RW", "Rwanda"), ("WS", "Samoa"), ("SM", "San Marino"),
        ("ST", "São Tomé & Príncipe"), ("SA", "Saudi Arabia"), ("SN", "Senegal"), ("RS", "Serbia"),
        ("SC", "Seychelles"), ("SL", "Sierra Leone"), ("SG", "Singapore"), ("SK", "Slovakia"),
        ("SI", "Slovenia"), ("SB", "Solomon Islands"), ("SO", "Somalia"), ("ZA", "South Africa"),
        ("KR", "South Korea"), ("SS", "South Sudan"), ("ES", "Spain"), ("LK", "Sri Lanka"),
        ("KN", "St. Kitts & Nevis"), ("LC", "St. Lucia"), ("VC", "St. Vincent & Grenadines"),
        ("SD", "Sudan"), ("SR", "Suriname"), ("SE", "Sweden"), ("CH", "Switzerland"),
        ("SY", "Syria"), ("TJ", "Tajikistan"), ("TZ", "Tanzania"), ("TH", "Thailand"),
        ("TL", "Timor-Leste"), ("TG", "Togo"), ("TO", "Tonga"), ("TT", "Trinidad & Tobago"),
        ("TN", "Tunisia"), ("TR", "Türkiye"), ("TM", "Turkmenistan"), ("TV", "Tuvalu"),
        ("UG", "Uganda"), ("UA", "Ukraine"), ("AE", "United Arab Emirates"),
        ("GB", "United Kingdom"), ("US", "United States"), ("UY", "Uruguay"), ("UZ", "Uzbekistan"),
        ("VU", "Vanuatu"), ("VA", "Vatican City"), ("VE", "Venezuela"), ("VN", "Vietnam"),
        ("YE", "Yemen"), ("ZM", "Zambia"), ("ZW", "Zimbabwe"),
    ]

    static let all: [Country] = catalog
        .map { Country(code: $0.0, name: $0.1) }
        .sorted { $0.name < $1.name }

    /// Sovereign-state codes — used to keep stray non-sovereign codes (e.g. a
    /// dependent territory tapped on the map) out of the Passport counts.
    static let codes: Set<String> = Set(all.map(\.code))

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

    // MARK: Continents

    private static let southAmericaCodes: Set<String> =
        ["AR", "BO", "BR", "CL", "CO", "EC", "GY", "PY", "PE", "SR", "UY", "VE", "FK", "GF"]

    /// Continent for an ISO code, resolved from the system region hierarchy
    /// (Americas is split N/S). Cached.
    static func continent(for code: String) -> Continent? {
        continentByCode[code.uppercased()]
    }

    static let continentByCode: [String: Continent] = {
        let continentIDs: Set<String> = ["002", "019", "142", "150", "009"]
        var map: [String: Continent] = [:]
        for country in all {
            var region: Locale.Region? = Locale.Region(country.code)
            while let r = region, !continentIDs.contains(r.identifier), r.identifier != "001" {
                region = r.containingRegion
            }
            let continent: Continent?
            switch region?.identifier {
            case "002": continent = .africa
            case "142": continent = .asia
            case "150": continent = .europe
            case "009": continent = .oceania
            case "019": continent = southAmericaCodes.contains(country.code) ? .southAmerica : .northAmerica
            default:    continent = nil
            }
            if let continent { map[country.code] = continent }
        }
        return map
    }()

    static func countries(in continent: Continent) -> [Country] {
        all.filter { continentByCode[$0.code] == continent }
    }

    /// How many curated sovereign states fall in each continent. This is the
    /// denominator the Passport shows ("7 / 44"), so a per-continent count can
    /// never exceed it (QA M-17: "24/23").
    static let continentCounts: [Continent: Int] = {
        Dictionary(grouping: all.compactMap { continentByCode[$0.code] }, by: { $0 })
            .mapValues(\.count)
    }()
}
