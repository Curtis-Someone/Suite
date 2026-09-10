import Foundation
import SwiftData

/// Singleton — not part of the relational schema. One row, created on first launch.
@Model
final class UserSettings {
    var homeCountryCode: String = ""
    var homeCountryName: String = ""
    var hasCompletedOnboarding: Bool = false
    var unitsPreference: UnitsPreference = UnitsPreference.metric
    var isProSubscriber: Bool = false   // local cache only — source of truth is the StoreKit entitlement check
    var appleUserID: String = ""        // "" when signed out
    var displayName: String = ""        // from Sign in with Apple, first time only
    var memberSince: Date = Date.now
    var packingReminders: Bool = false
    var tripRecaps: Bool = false
    /// Pro · off by default — lets accepted friends see your passport.
    var friendsCanSeePassport: Bool = false
    /// Your friend-invite code, generated once on first use.
    var myShareCode: String = ""

    init() {
        self.hasCompletedOnboarding = false
        self.unitsPreference = .metric
        self.isProSubscriber = false
        self.appleUserID = ""
        self.displayName = ""
        self.memberSince = .now
        self.packingReminders = false
        self.tripRecaps = false
        self.friendsCanSeePassport = false
        self.myShareCode = ""
    }
}

enum UnitsPreference: String, Codable {
    case metric, imperial
}

extension UserSettings {
    /// The one settings row — fetched, or created and inserted if missing.
    static func current(in context: ModelContext) -> UserSettings {
        if let existing = try? context.fetch(FetchDescriptor<UserSettings>()).first {
            return existing
        }
        let created = UserSettings()
        context.insert(created)
        return created
    }
}
