import SwiftUI
import SwiftData

/// Router. Onboarding until `UserSettings.hasCompletedOnboarding`, then the
/// main shell. Launch args keep the batch-2/3 harnesses reachable.
struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Query private var settings: [UserSettings]

    var body: some View {
        let args = ProcessInfo.processInfo.arguments
        Group {
            if args.contains("-dataCheck") {
                DataCheckView()
            } else if args.contains("-gallery") {
                ComponentGallery()
            } else if let screen = screenArg(args) {
                screen
            } else if settings.first?.hasCompletedOnboarding == true {
                MainAppShell()
            } else {
                OnboardingFlow()
            }
        }
        .task {
            if let settings = settings.first { auth.restoreSession(from: settings) }
        }
    }

    /// Dev: `-screen <profile|settings|search|share|permLocation|permNotif>` — jump
    /// straight to a Batch-8 global screen for screenshot verification.
    private func screenArg(_ args: [String]) -> AnyView? {
        guard let i = args.firstIndex(of: "-screen"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "profile":      return AnyView(ProfileView())
        case "settings":     return AnyView(NavigationStack { SettingsView() })
        case "search":       return AnyView(SearchView())
        case "share":        return AnyView(ShareCardView())
        case "permLocation": return AnyView(PermissionView(kind: .location) {})
        case "permNotif":    return AnyView(PermissionView(kind: .notifications) {})
        case "error":        return AnyView(ErrorStateView(retry: {}))
        case "reward1":      return AnyView(RewardDemo(.init(kind: .packed, title: "All packed for Lisbon.", message: "Every one of the 20 items is in the bag. 9 days to go.")))
        case "reward2":      return AnyView(RewardDemo(.init(kind: .tripComplete, title: "Trip complete.", message: "Kyoto in autumn is stamped in your passport. 6 days, 2 cities.")))
        case "reward3":      return AnyView(RewardDemo(.init(kind: .country, title: "That's your 8th country.", message: "4% of the world explored, and Europe is now 7 of 51.")))
        case "reward4":      return AnyView(RewardDemo(.init(kind: .milestone, title: "10 countries.", message: "5% of the world. Keep the passport moving.")))
        case "paywall":      return AnyView(PaywallView())
        case "purchaseDone": return AnyView(PurchaseConfirmationView {})
        case "exportDoc":    return AnyView(ScrollView { PackingListDocument.sample })
        case "dataExport":   return AnyView(Color.clear.sheet(isPresented: .constant(true)) { DataExportSheet() })
        case "proBenefits":  return AnyView(ProBenefitsView())
        case "upsellTrip":   return AnyView(Color.black.opacity(0.3).ignoresSafeArea().sheet(isPresented: .constant(true)) { UpsellSheet(moment: .thirdActiveTrip) })
        default:             return nil
        }
    }
}

/// Dev-only: shows a reward overlay over a blank ground for screenshotting.
private struct RewardDemo: View {
    let reward: Reward
    init(_ reward: Reward) { self.reward = reward }
    var body: some View {
        Theme.Palette.ground.ignoresSafeArea()
            .task {
                try? await Task.sleep(for: .milliseconds(400))
                RewardPresenter.present(reward)
            }
    }
}
