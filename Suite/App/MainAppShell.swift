import SwiftUI

/// The post-onboarding shell: three tabs behind the custom bottom nav.
/// Opens on Suitcase (the core loop).
struct MainAppShell: View {
    @State private var tab: SuiteTab = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-tab"), i + 1 < a.count {
            switch a[i + 1] {
            case "map":      return .map
            case "passport": return .passport
            default:         return .suitcase
            }
        }
        return .suitcase
    }()

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .map:      MapTabView()
                case .suitcase: SuitcaseTabView()
                case .passport: PassportTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavBar(selection: $tab)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
    }
}
