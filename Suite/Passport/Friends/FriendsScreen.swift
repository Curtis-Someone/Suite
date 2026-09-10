import SwiftUI
import SwiftData

/// Passport → Friends, as its own screen. Reached from the people button in the
/// Passport header. Wraps `FriendsListView`; adding a friend and opening one are
/// handled by the caller's navigation stack.
struct FriendsScreen: View {
    var myName: String
    var myCountryCount: Int
    var myWorldPercent: Double
    var onOpenFriend: (Friend) -> Void
    var onAddFriend: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Friend.addedAt, order: .reverse) private var friends: [Friend]

    private var acceptedCount: Int { friends.accepted.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                FriendsListView(
                    myName: myName,
                    myCountryCount: myCountryCount,
                    myWorldPercent: myWorldPercent,
                    onOpenFriend: onOpenFriend,
                    onAddFriend: onAddFriend)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.Palette.border))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Friends")
                    .font(.Suite.title).tracking(25 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(acceptedCount == 0 ? "Compare passports with people you travel with"
                     : acceptedCount == 1 ? "1 friend"
                     : "\(acceptedCount) friends")
                    .font(.Suite.data)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            Button(action: onAddFriend) {
                SuiteIconView(icon: .plus, size: 20, color: Theme.Palette.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.Palette.border))
            }
            .accessibilityLabel("Add a friend")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }
}
