import SwiftUI

/// G5 · Generic error state — icon, headline, one line of copy, "Try again".
/// Defaults read as a lost-connection state (the handoff's "We lost the signal.").
struct ErrorStateView: View {
    var title: String = "We lost the signal."
    var message: String = "Check your connection and we'll pick up where you left off."
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            SuiteIconView(icon: .wifiOff, size: 64, color: Theme.Palette.textTertiary)
            Spacer().frame(height: 30)
            Text(title)
                .font(.Suite.title).tracking(25 * -0.02)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer().frame(height: 12)
            Text(message)
                .font(.Suite.bodyL)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.Palette.textSecondary)
            if let retry {
                Spacer().frame(height: 34)
                Button(action: retry) {
                    Text("Try again")
                        .font(.archivo(16, .bold))
                        .foregroundStyle(Theme.Palette.onAccent)
                        .frame(minHeight: Theme.Size.ctaCompact)
                        .padding(.horizontal, 34)
                        .background(Theme.Palette.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.ground.ignoresSafeArea())
    }
}
