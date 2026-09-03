import Foundation
import SwiftData

// Schema per `Documentos/SuiteModels.swift` (Ivan). CloudKit-compatible:
// every stored property defaulted, no `.unique`, to-many default to `[]`,
// to-one optional.

@Model
final class Trip {
    var tripID: UUID = UUID()                  // loose link target for VisitedPlace.sourceTripID
    var name: String = ""                     // usually the destination, but user-editable
    var tripType: String = ""                 // PackingPreset.tripTypes id, e.g. "mountains"
    var iconName: String = "luggage"          // Lucide glyph on the trip card — from the trip type, else activity picks
    var destinationCity: String = ""
    var destinationCountry: String = ""
    var destinationCountryCode: String = ""    // ISO 3166-1 alpha-2 — weather lookup + passport stats
    var startDate: Date = Date.now
    var endDate: Date = Date.now
    var createdAt: Date = Date.now
    var isArchived: Bool = false               // manual archive, separate from date-derived status

    @Relationship(deleteRule: .cascade, inverse: \Suitcase.trip)
    var suitcases: [Suitcase] = []

    @Relationship(deleteRule: .cascade, inverse: \WeatherDay.trip)
    var weatherDays: [WeatherDay] = []

    @Relationship(deleteRule: .cascade, inverse: \Traveler.trip)
    var travelers: [Traveler] = []             // Pro only — stays empty on free tier

    init(
        name: String,
        destinationCity: String,
        destinationCountry: String,
        destinationCountryCode: String,
        startDate: Date,
        endDate: Date
    ) {
        self.name = name
        self.destinationCity = destinationCity
        self.destinationCountry = destinationCountry
        self.destinationCountryCode = destinationCountryCode
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = .now
        self.isArchived = false
    }

    /// Derived, not stored — status comes from today's date vs. the trip dates.
    var status: TripStatus {
        let now = Date.now
        if now < startDate { return .upcoming }
        if now > endDate { return .past }
        return .active
    }
}

enum TripStatus: String, Codable {
    case upcoming, active, past
}
