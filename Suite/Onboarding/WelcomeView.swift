import SwiftUI

/// 06 · Welcome — logomark, wordmark, tagline. Sign in with Apple, or skip
/// (the app is local-first; sign-in only matters for Pro sync later).
struct WelcomeView: View {
    var onSignIn: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 56) {
            Spacer()
            VStack(spacing: 20) {
                Image("SuiteLogomark")
                    .resizable().scaledToFit()
                    .frame(width: 216, height: 216)
                Wordmark(size: 40)
                Text("Map, pack and stamp\nevery trip you take.")
                    .font(.Suite.bodyL)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            VStack(spacing: 14) {
                SuiteButton(title: "Sign in", action: onSignIn)
                SuiteButton(title: "Skip for now", style: .secondary, action: onSkip)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.surface.ignoresSafeArea())
    }
}
