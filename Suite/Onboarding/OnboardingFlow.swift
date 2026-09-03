import SwiftUI
import SwiftData

/// Splash → tour → welcome → sign in (Apple) → home country → setting-up → app.
/// Finishing sets `UserSettings.hasCompletedOnboarding`; `RootView` observes
/// that and swaps in the main shell.
struct OnboardingFlow: View {
    @Environment(\.modelContext) private var context
    @State private var step: Step = .initial

    enum Step: String {
        case splash, tour, welcome, auth, homeCountry, settingUp

        /// Dev: `-step welcome` jumps straight to a screen for review.
        static var initial: Step {
            guard let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-step"),
                  i + 1 < ProcessInfo.processInfo.arguments.count,
                  let s = Step(rawValue: ProcessInfo.processInfo.arguments[i + 1])
            else { return .splash }
            return s
        }
    }

    var body: some View {
        content
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: step)
            .task {
                // Dev: run the real seed + finish path without tapping through.
                if ProcessInfo.processInfo.arguments.contains("-autopilot") {
                    seedHomeCountry(code: "PT", name: "Portugal")
                    finish()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .splash:
            SplashView { go(.tour) }
        case .tour:
            OnboardingTourView { go(.welcome) }
        case .welcome:
            WelcomeView(onSignIn: { go(.auth) }, onSkip: { go(.homeCountry) })
        case .auth:
            AuthFormView(onSubmit: { go(.homeCountry) },
                         onSkip: { go(.homeCountry) },
                         onBack: { go(.welcome) })
        case .homeCountry:
            HomeCountryView { code, name in
                seedHomeCountry(code: code, name: name)
                go(.settingUp)
            }
        case .settingUp:
            SettingUpView(onDone: finish)
        }
    }

    private func go(_ next: Step) { withAnimation { step = next } }

    private func seedHomeCountry(code: String, name: String) {
        let settings = UserSettings.current(in: context)
        settings.homeCountryCode = code
        settings.homeCountryName = name
        context.insert(VisitedPlace(countryName: name, countryCode: code, isHomeCountry: true))
    }

    private func finish() {
        UserSettings.current(in: context).hasCompletedOnboarding = true
        try? context.save()
    }
}
