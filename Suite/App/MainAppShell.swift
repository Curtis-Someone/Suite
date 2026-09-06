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
        // A paged TabView so a horizontal finger-swipe moves between tabs;
        // the custom pill stays the visible control, bound to the same selection.
        // The top safe area is left intact so each tab's own header stays below
        // the status bar and keeps its tap targets; Map bleeds to the top edge
        // via its own `.ignoresSafeArea()` on the map and background layers.
        TabView(selection: $tab) {
            MapTabView().tag(SuiteTab.map)
            SuitcaseTabView().tag(SuiteTab.suitcase)
            PassportTabView().tag(SuiteTab.passport)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomNavBar(selection: $tab)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
    }
}
