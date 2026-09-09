import Foundation
import SwiftData

/// Passport tab / rewards stats. Tied to a Trip loosely via `sourceTripID`
/// rather than a real relationship — a visited stamp must survive even if the
/// trip is later deleted.
@Model
final class VisitedPlace {
    var countryName: String = ""
    var countryCode: String = ""
    var cityName: String = ""
    var firstVisitedDate: Date = Date.now
    var isHomeCountry: Bool = false     // seeded at onboarding — keeps world% above 0
    var sourceTripID: UUID?

    init(
        countryName: String,
        countryCode: String,
        cityName: String = "",
        isHomeCountry: Bool = false,
        sourceTripID: UUID? = nil
    ) {
        self.countryName = countryName
        self.countryCode = countryCode
        self.cityName = cityName
        self.firstVisitedDate = .now
        self.isHomeCountry = isHomeCountry
        self.sourceTripID = sourceTripID
    }
}

extension VisitedPlace {
    /// Stamps the "Visited" toggle must never delete: the onboarding home-country
    /// seed and any stamp auto-added by completing a trip. Both are meant to be
    /// permanent — only manually-added visits can be removed via that control.
    var isProtectedStamp: Bool { isHomeCountry || sourceTripID != nil }
}
