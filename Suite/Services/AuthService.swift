import Foundation
import SwiftData
import Observation

/// Sign in with Apple only — no server, no user database. The Apple identity
/// (stable user id + name) is stored on the `UserSettings` singleton.
@Observable
final class AuthService {
    private(set) var appleUserID: String?
    var isSignedIn: Bool { appleUserID != nil }

    func restoreSession(from settings: UserSettings) {
        appleUserID = settings.appleUserID.isEmpty ? nil : settings.appleUserID
    }

    func signInWithApple(userID: String, fullName: String?, context: ModelContext) {
        let settings = UserSettings.current(in: context)
        settings.appleUserID = userID
        if let fullName, !fullName.isEmpty { settings.displayName = fullName }
        else if settings.displayName.isEmpty { settings.displayName = "Traveller" }
        try? context.save()
        appleUserID = userID
    }

    func signOut(context: ModelContext) {
        let settings = UserSettings.current(in: context)
        settings.appleUserID = ""
        settings.displayName = ""
        try? context.save()
        appleUserID = nil
    }
}
