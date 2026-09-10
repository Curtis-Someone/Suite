import Foundation
import SwiftData

/// Friend-layer operations. v1 has no sync yet, so "add" records a local
/// pending row; once CKShare lands, `addByCode` resolves the code to a real
/// participant and these same call sites stay put.
@MainActor
enum FriendsService {

    /// Short invite code — no easily-confused characters (0/O, 1/I).
    static func makeCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in alphabet.randomElement()! })
    }

    /// Your own code — generated once, kept on `UserSettings`.
    static func myCode(_ settings: UserSettings) -> String {
        if settings.myShareCode.isEmpty { settings.myShareCode = makeCode() }
        return settings.myShareCode
    }

    static func inviteURL(code: String) -> URL {
        URL(string: "https://suite.app/f/\(code)")!
    }

    static func shareMessage(code: String) -> String {
        "Add me on Suite — my code is \(code)\n\(inviteURL(code: code).absoluteString)"
    }

    /// Someone pasted a code. Returns nil if it's obviously not a code.
    @discardableResult
    static func addByCode(_ raw: String, in context: ModelContext) -> Friend? {
        let code = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://suite.app/f/", with: "")
            .uppercased()
        guard code.count >= 6, code.count <= 12 else { return nil }
        let friend = Friend(displayName: "Pending invite",
                            shareCode: code,
                            status: .outgoingRequest)
        context.insert(friend)
        try? context.save()
        return friend
    }

    static func accept(_ friend: Friend, sharedTripCount: Int, in context: ModelContext) {
        friend.status = .accepted
        try? context.save()
        RewardEngine.friendAdded(name: friend.displayName, sharedTripCount: sharedTripCount)
    }

    static func decline(_ friend: Friend, in context: ModelContext) {
        context.delete(friend)
        try? context.save()
    }
}

extension Array where Element == Friend {
    var accepted: [Friend] { filter { $0.status == .accepted } }
    var incomingRequests: [Friend] { filter { $0.status == .incomingRequest } }
    /// Accepted friends who've turned passport sharing on, best-travelled first.
    var visibleLeaderboard: [Friend] {
        accepted.filter(\.sharesPassport).sorted { $0.countryCount > $1.countryCount }
    }
}
