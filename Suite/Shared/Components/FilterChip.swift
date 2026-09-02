import SwiftUI

/// Small filter pill — 32 pt tall. Active = amber / dark (Archivo 600);
/// inactive = `surfaceSunken` / `textBody` (Archivo 500).
struct FilterChip: View {
    var title: String
    var isActive: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.archivo(12, isActive ? .semibold : .medium))
                .foregroundStyle(isActive ? Theme.Palette.onAccent : Theme.Palette.textBody)
                .padding(.horizontal, 15)
                .frame(height: 32)
                .background(isActive ? Theme.Palette.accent : Theme.Palette.surfaceSunken, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
