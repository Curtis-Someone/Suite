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
        // the custom bottom bar stays the visible control, bound to the same selection.
        TabView(selection: $tab) {
            MapTabView().tag(SuiteTab.map)
            SuitcaseTabView().tag(SuiteTab.suitcase)
            PassportTabView().tag(SuiteTab.passport)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The pill is a pure overlay — it reserves no layout space, so the tab
        // content runs full-bleed to the screen edge and scrolls *behind* it
        // (each tab already pads its own content clear of the pill).
        .overlay(alignment: .bottom) {
            BottomNavBar(selection: $tab)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
    }
}
