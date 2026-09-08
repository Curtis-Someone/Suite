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
        // One screen at a time, switched by the bottom bar. No horizontal
        // pager — the Map tab needs every finger-drag for panning the map.
        Group {
            switch tab {
            case .map:      MapTabView()
            case .suitcase: SuitcaseTabView()
            case .passport: PassportTabView()
            }
        }
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
