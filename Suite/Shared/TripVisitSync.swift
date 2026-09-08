import Foundation
import SwiftData

/// Turns finished trips into map visits automatically. Once a trip has a suitcase
/// and its end date is in the past, its country should show on the Map (and in
/// the Passport) without the user tapping "Mark complete" in the checklist.
///
/// Idempotent — a visit is only added when the trip isn't already linked to one
/// (`sourceTripID`) and the country isn't visited yet, so it's safe to run on
/// every launch.
enum TripVisitSync {
    static func run(context: ModelContext) {
        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        let visits = (try? context.fetch(FetchDescriptor<VisitedPlace>())) ?? []
        let linkedTripIDs = Set(visits.compactMap(\.sourceTripID))
        var visitedCodes = Set(visits.map { $0.countryCode.uppercased() })

        var added = false
        for trip in trips where trip.status == .past
            && !trip.suitcases.isEmpty
            && !trip.destinationCountryCode.isEmpty
            && !linkedTripIDs.contains(trip.tripID)
            && !visitedCodes.contains(trip.destinationCountryCode.uppercased()) {
            context.insert(VisitedPlace(
                countryName: trip.destinationCountry,
                countryCode: trip.destinationCountryCode,
                cityName: trip.destinationCity,
                sourceTripID: trip.tripID
            ))
            visitedCodes.insert(trip.destinationCountryCode.uppercased())
            added = true
        }
        if added { try? context.save() }
    }
}
