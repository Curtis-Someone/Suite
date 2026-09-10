import SwiftUI

/// Initial-circle avatar. No photo store in v1 — the circle carries one or two
/// letters over a faint amber fill. Used in the friend list, leaderboard, the
/// Map "whose map" strip, and the friend-request card.
struct FriendAvatar: View {
    var name: String
    var size: CGFloat = 40
    var selected: Bool = false

    private var initials: String {
        let words = name.split(separator: " ")
        let first = words.first?.first.map(String.init) ?? "?"
        let second = words.count > 1 ? (words.last?.first.map(String.init) ?? "") : ""
        return (first + second).uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.archivo(size * 0.38, .bold))
            .foregroundStyle(Theme.Palette.accent)
            .frame(width: size, height: size)
            .background(Theme.Palette.accent.opacity(0.14), in: Circle())
            .overlay(
                Circle().strokeBorder(
                    selected ? Theme.Palette.accent : Theme.Palette.border,
                    lineWidth: selected ? 2 : 1)
            )
            .accessibilityHidden(true)
    }
}
