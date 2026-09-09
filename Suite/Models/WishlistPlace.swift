import Foundation
import SwiftData

/// A place the user wants to go. Country-level when `cityName` is empty,
/// city-level otherwise — the "someday" mirror of `VisitedPlace`.
@Model
final class WishlistPlace {
    var countryName: String = ""
    var countryCode: String = ""
    var cityName: String = ""
    var addedDate: Date = Date.now

    init(countryName: String, countryCode: String, cityName: String = "") {
        self.countryName = countryName
        self.countryCode = countryCode
        self.cityName = cityName
        self.addedDate = .now
    }
}
