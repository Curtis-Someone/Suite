import SwiftUI

/// Bottom sheet · "Whose map?" — you plus any friend who shares their passport.
/// Picking one swaps the visited-region shading on the map.
struct WhoseMapSheet: View {
    var myName: String
    var friends: [Friend]
    var selected: Friend?
    var onSelect: (Friend?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Whose map?")
                .font(.Suite.titleS).tracking(22 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 20)

            row(name: myName.isEmpty ? "You" : myName, isMe: true, isSelected: selected == nil) {
                onSelect(nil); dismiss()
            }
            ForEach(friends) { friend in
                row(name: friend.displayName, isMe: false, isSelected: selected?.id == friend.id) {
                    onSelect(friend); dismiss()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }

    private func row(name: String, isMe: Bool, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                FriendAvatar(name: name, size: 34, selected: isSelected)
                Text(isMe ? "\(name) · your map" : name)
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
                if isSelected {
                    SuiteIconView(icon: .check, size: 16, color: Theme.Palette.accent)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip)
                .strokeBorder(isSelected ? Theme.Palette.accent : Theme.Palette.border,
                              lineWidth: isSelected ? 1.6 : 1))
        }
        .buttonStyle(.plain)
    }
}
