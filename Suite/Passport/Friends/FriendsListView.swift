import SwiftUI
import SwiftData

/// Passport → Friends. A compact leaderboard over a plain friend list, with a
/// requests row on top when there are any. Empty state keeps the percentile
/// stat above it visible (the caller handles that) and offers "Add a friend".
struct FriendsListView: View {
    var myName: String
    var myCountryCount: Int
    var myWorldPercent: Double
    var onOpenFriend: (Friend) -> Void
    var onAddFriend: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Friend.addedAt, order: .reverse) private var friends: [Friend]

    private var requests: [Friend] { friends.incomingRequests }
    private var accepted: [Friend] { friends.accepted }
    private var leaderboard: [LeaderRow] {
        var rows = accepted.filter(\.sharesPassport).map {
            LeaderRow(id: $0.persistentModelID.hashValue, name: $0.displayName,
                      countryCount: $0.countryCount, isMe: false)
        }
        rows.append(LeaderRow(id: 0, name: myName.isEmpty ? "You" : myName,
                              countryCount: myCountryCount, isMe: true))
        return rows.sorted { $0.countryCount > $1.countryCount }
    }

    var body: some View {
        VStack(spacing: 14) {
            if accepted.isEmpty && requests.isEmpty {
                emptyState
            } else {
                if !requests.isEmpty { requestsSection }
                if leaderboard.count > 1 { leaderboardCard }
                if !accepted.isEmpty { friendListCard }
                addFriendButton
            }
        }
    }

    // MARK: Requests

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            KickerLabel("Requests · \(requests.count)")
            ForEach(requests) { friend in
                FriendRequestCard(
                    name: friend.displayName,
                    onAccept: { FriendsService.accept(friend, sharedTripCount: friend.sharedTrips.count, in: context) },
                    onDecline: { FriendsService.decline(friend, in: context) })
            }
        }
    }

    // MARK: Leaderboard

    private var leaderboardCard: some View {
        SuiteCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ranked by countries").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.Suite.data)
                            .foregroundStyle(Theme.Palette.textTertiary)
                            .frame(width: 18, alignment: .trailing)
                        FriendAvatar(name: row.name, size: 30, selected: row.isMe)
                        Text(row.name)
                            .font(.archivo(14, row.isMe ? .bold : .medium))
                            .foregroundStyle(Theme.Palette.textHeading)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text("\(row.countryCount)")
                            .font(.Suite.data)
                            .foregroundStyle(Theme.Palette.textBody)
                    }
                    .padding(.vertical, 4)
                    .background(row.isMe ? Theme.Palette.accent.opacity(0.08) : .clear,
                               in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                }
            }
        }
    }

    // MARK: Friend list

    private var friendListCard: some View {
        SuiteCard(padding: 8) {
            VStack(spacing: 0) {
                ForEach(Array(accepted.enumerated()), id: \.element.id) { index, friend in
                    if index > 0 { Rectangle().fill(Theme.Palette.divider).frame(height: 1).padding(.leading, 54) }
                    Button { onOpenFriend(friend) } label: {
                        HStack(spacing: 12) {
                            FriendAvatar(name: friend.displayName, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.displayName)
                                    .font(.archivo(14, .semibold))
                                    .foregroundStyle(Theme.Palette.textPrimary)
                                    .lineLimit(1)
                                Text(friend.sharesPassport
                                     ? "\(friend.countryCount) countries · \(Int((friend.worldPercent * 100).rounded()))%"
                                     : "Passport not shared")
                                    .font(.jetBrainsMono(11))
                                    .foregroundStyle(Theme.Palette.textTertiary)
                            }
                            Spacer(minLength: 6)
                            SuiteIconView(icon: .chevronRight, size: 15)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.suitePress)
                }
            }
        }
    }

    private var addFriendButton: some View {
        Button(action: onAddFriend) {
            HStack(spacing: 8) {
                SuiteIconView(icon: .plus, size: 16, color: Theme.Palette.textPrimary)
                Text("Add a friend").font(.archivo(14, .semibold)).foregroundStyle(Theme.Palette.textPrimary)
            }
            .frame(maxWidth: .infinity).frame(height: 46)
            .overlay(Capsule().strokeBorder(Theme.Palette.textPrimary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        SuiteCard(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                LucideIcon(name: "users", size: 24, color: Theme.Palette.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.Palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                Text("No friends yet")
                    .font(.Suite.titleS).tracking(22 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("Add a friend to compare passports and see whose map you're both filling in.")
                    .font(.Suite.bodyS)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Theme.Palette.textSecondary)
                SuiteButton(title: "Add a friend", showsLeadingPlus: true, action: onAddFriend)
                    .padding(.top, 4)
            }
        }
    }

    private struct LeaderRow: Identifiable {
        let id: Int
        let name: String
        let countryCount: Int
        let isMe: Bool
    }
}
