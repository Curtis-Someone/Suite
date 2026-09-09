import Foundation

/// External legal URLs surfaced on the paywall and the auth screen.
/// Guideline 3.1.2 requires both to be functional links for an app with an
/// auto-renewable subscription.
enum SuiteLinks {
    /// Apple's Standard License Agreement. Apple accepts this as the app's
    /// Terms of Use (EULA) when no custom terms are supplied.
    static let termsOfUse = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

    /// Suite's privacy policy.
    static let privacyPolicy = "https://suiteapp.com/privacy"

    #warning("Privacy Policy URL is a placeholder — host Suite's real policy and update this before App Store submission (see APP_STORE.md → 'Privacy Policy URL'). Batch 2 / H-02 stays open until then.")
}
