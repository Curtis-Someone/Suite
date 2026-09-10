import SwiftUI
import SwiftData

/// Bottom sheet · add a traveler to a trip. Friends first (tap to add directly —
/// the relationship already exists), with "Share a link instead" below for
/// anyone not yet a friend.
struct TravelerPickerSheet: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Friend.addedAt, order: .reverse) private var friends: [Friend]
    @State private var showAddFriends = false

    private var candidates: [Friend] {
        let taken = Set(trip.travelers.map(\.name))
        return friends.accepted.filter { !taken.contains($0.displayName) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add a traveler")
                .font(.Suite.titleS).tracking(22 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 20)

            if candidates.isEmpty {
                Text("No friends to add yet.")
                    .font(.Suite.bodyS)
                    .foregroundStyle(Theme.Palette.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(candidates) { friend in
                            Button { add(friend) } label: {
                                HStack(spacing: 12) {
                                    FriendAvatar(name: friend.displayName, size: 36)
                                    Text(friend.displayName)
                                        .font(.archivo(15, .semibold))
                                        .foregroundStyle(Theme.Palette.textPrimary)
                                    Spacer()
                                    SuiteIconView(icon: .plus, size: 16, color: Theme.Palette.accent)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip)
                                    .strokeBorder(Theme.Palette.border))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button { showAddFriends = true } label: {
                HStack(spacing: 8) {
                    SuiteIconView(icon: .share, size: 15, color: Theme.Palette.textSecondary)
                    Text("Share a link instead")
                        .font(.archivo(14, .semibold))
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                .frame(maxWidth: .infinity).frame(height: 44)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showAddFriends) { AddFriendsView() }
    }

    private func add(_ friend: Friend) {
        trip.travelers.append(Traveler(name: friend.displayName, trip: trip))
        try? context.save()
        dismiss()
    }
}
