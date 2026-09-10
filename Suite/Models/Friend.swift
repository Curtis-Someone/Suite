import Foundation
import SwiftData

/// Pro — a friendship record. v1 connects people by share link / QR only (the
/// same CKShare-style invite the trip-collaborator flow uses, pointed at a
/// friendship instead of a trip), so the invite is a `shareCode`.
///
/// Passport visibility is opt-in **per relationship**, off by default: nothing
/// about the other person shows until they've accepted *and* turned sharing on
/// (`sharesPassport`). Their passport figures ride along as a snapshot —
/// seeded locally today, refreshed from their shared copy once iCloud sync ships.
@Model
final class Friend {
    var displayName: String = ""
    var shareCode: String = ""
    var statusRaw: String = FriendStatus.incomingRequest.rawValue
    /// They have allowed this relationship to see their passport.
    var sharesPassport: Bool = false
    var addedAt: Date = Date.now

    /// Snapshot of the friend's passport — empty until `sharesPassport` is on.
    var countryCodes: [String] = []
    var cityCount: Int = 0

    /// Trips you were both on. Empty until you've co-shared a trip (needs the
    /// collaborator/sync flow); demo-seeded meanwhile.
    var sharedTrips: [SharedTripInfo] = []

    init(displayName: String,
         shareCode: String = "",
         status: FriendStatus = .accepted,
         sharesPassport: Bool = false,
         countryCodes: [String] = [],
         cityCount: Int = 0,
         sharedTrips: [SharedTripInfo] = []) {
        self.displayName = displayName
        self.shareCode = shareCode
        self.statusRaw = status.rawValue
        self.sharesPassport = sharesPassport
        self.countryCodes = countryCodes
        self.cityCount = cityCount
        self.sharedTrips = sharedTrips
        self.addedAt = .now
    }
}

/// A trip you and a friend were both on.
struct SharedTripInfo: Codable, Hashable, Identifiable {
    var destination: String
    var countryCode: String
    var dateRange: String
    var id: String { destination + dateRange }
}

enum FriendStatus: String {
    /// They asked to be your friend — shows in the requests row.
    case incomingRequest
    /// You entered their code; waiting on them.
    case outgoingRequest
    case accepted
}

extension Friend {
    var status: FriendStatus {
        get { FriendStatus(rawValue: statusRaw) ?? .accepted }
        set { statusRaw = newValue.rawValue }
    }

    /// UN-country count from the snapshot, deduped.
    var countryCount: Int {
        Set(countryCodes.map { $0.uppercased() }).intersection(Countries.codes).count
    }
    var worldPercent: Double {
        Double(countryCount) / Double(PassportStats.unCountryTotal)
    }

    /// One or two letters for the avatar circle.
    var initials: String {
        let words = displayName.split(separator: " ")
        let first = words.first?.first.map(String.init) ?? "?"
        let second = words.count > 1 ? (words.last?.first.map(String.init) ?? "") : ""
        return (first + second).uppercased()
    }
}
