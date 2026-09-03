import Foundation
import SwiftData

/// Open-Meteo cache, one row per trip day. Wired up in batch 5.
@Model
final class WeatherDay {
    var date: Date = Date.now
    var highTemp: Double = 0
    var lowTemp: Double = 0
    var precipitationChance: Double = 0
    var conditionCode: Int = 0        // Open-Meteo WMO weather code
    var fetchedAt: Date = Date.now    // decides when the cache is stale
    var trip: Trip?

    init(
        date: Date,
        highTemp: Double,
        lowTemp: Double,
        precipitationChance: Double,
        conditionCode: Int,
        trip: Trip? = nil
    ) {
        self.date = date
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.precipitationChance = precipitationChance
        self.conditionCode = conditionCode
        self.fetchedAt = .now
        self.trip = trip
    }
}
