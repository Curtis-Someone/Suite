import SwiftUI

/// A single incoming friend request — a card, not a screen. Lives in the
/// requests row above the friend list (Suite has no notification centre yet).
/// Same visual weight as other cards on the ground: white fill, 1px border.
struct FriendRequestCard: View {
    var name: String
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                FriendAvatar(name: name, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.archivo(15, .bold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .lineLimit(1)
                    Text("wants to be your friend")
                        .font(.Suite.bodyS)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.archivo(14, .bold))
                        .foregroundStyle(Theme.Palette.onAccent)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Theme.Palette.accent, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onDecline) {
                    Text("Decline")
                        .font(.archivo(14, .bold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .overlay(Capsule().strokeBorder(Theme.Palette.textPrimary, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).strokeBorder(Theme.Palette.border))
    }
}
