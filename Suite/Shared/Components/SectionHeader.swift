import SwiftUI

/// Section header — bold title (Archivo 700 / 22, −0.02em) with a hairline
/// rule filling the remaining width.
struct SectionHeader: View {
    var title: String

    var body: some View {
        HStack(spacing: 18) {
            Text(title)
                .font(.Suite.titleS)
                .tracking(22 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
            Rectangle()
                .fill(Theme.Palette.border)
                .frame(height: 1)
        }
    }
}

/// Uppercase mono kicker — JetBrains Mono 500 / 11, +0.16em tracking.
/// Sits above cards and groups throughout the app.
struct KickerLabel: View {
    var text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.Suite.label)
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Theme.Palette.textTertiary)
    }
}
