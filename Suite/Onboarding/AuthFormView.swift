import SwiftUI
import SwiftData
import AuthenticationServices

/// 07 · Sign in. Apple only — no server, no passwords (per Ivan). `onSubmit`
/// fires after Sign in with Apple succeeds.
struct AuthFormView: View {
    var onSubmit: () -> Void
    var onSkip: () -> Void
    var onBack: () -> Void

    @Environment(AuthService.self) private var auth
    @Environment(\.modelContext) private var context
    @State private var error: String?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Palette.ground.ignoresSafeArea()
            hero

            VStack(spacing: 0) {
                Spacer(minLength: 236)
                sheet
            }
            .ignoresSafeArea(edges: .bottom)

            backButton
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            auth.signInWithApple(userID: credential.user,
                                 fullName: name.isEmpty ? nil : name,
                                 context: context)
            error = nil
            onSubmit()
        case .failure(let err):
            if (err as? ASAuthorizationError)?.code == .canceled { return }
            error = "Apple sign-in failed. Try again."
        }
    }

    private var hero: some View {
        ZStack {
            Color(hex: 0x0A0A0A)   // the hero is always dark (night-map treatment), both modes
            LinearGradient(
                colors: [.black.opacity(0.6), .black.opacity(0.12), .black.opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 10) {
                Image("SuiteLogomark")
                    .resizable().scaledToFit()
                    .frame(width: 56, height: 56)
                    .colorInvert()
                Wordmark(size: 26, wordColor: .white)
            }
            .padding(.top, 120)
        }
        .frame(height: 460)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
    }

    private var backButton: some View {
        HStack {
            Button(action: onBack) {
                SuiteIconView(icon: .chevronLeft, size: 22, color: Theme.Palette.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Theme.Palette.ground.opacity(0.94), in: Circle())
            }
            Spacer()
        }
        .padding(.leading, 24)
        .padding(.top, 58)
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sign in to Suite.")
                .font(.Suite.titleL).tracking(27 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("One tap with Apple. Your trips stay on your\ndevice — Suite never sees an account.")
                .font(.Suite.bodyL)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.Palette.textSecondary)

            SignInWithAppleButton(.continue,
                onRequest: { $0.requestedScopes = [.fullName] },
                onCompletion: handleApple)
                .signInWithAppleButtonStyle(.black)
                .frame(height: Theme.Size.cta)
                .clipShape(Capsule())

            if let error {
                Text(error)
                    .font(.archivo(13))
                    .foregroundStyle(Theme.Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Skip for now", action: onSkip)
                .font(.archivo(15, .semibold))
                .foregroundStyle(Theme.Palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            Text("By continuing you agree to our [Terms of Use](\(SuiteLinks.termsOfUse)).\nOur [Privacy Policy](\(SuiteLinks.privacyPolicy)) applies.")
                .font(.archivo(11))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.Palette.textTertiary)
                .tint(Theme.Palette.textSecondary)
                .frame(maxWidth: .infinity)
        }
        .padding(28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.ground)
        .clipShape(.rect(topLeadingRadius: 34, topTrailingRadius: 34))
    }
}
