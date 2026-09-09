import Foundation
import SwiftData

/// Pro — collaborators via CKShare. Model only; the invite flow is batch 11.
@Model
final class Traveler {
    var name: String = ""
    var cloudKitParticipantID: String = ""   // links to the CKShare participant once synced
    var trip: Trip?

    init(name: String, trip: Trip? = nil) {
        self.name = name
        self.trip = trip
    }
}
