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
        // One tab at a time, switched by the pill. No horizontal pager: the
        // Map tab needs every finger-drag for panning the world map.
        Group {
            switch tab {
            case .map:      MapTabView()
            case .suitcase: SuitcaseTabView()
            case .passport: PassportTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The pill floats *over* the content; `safeAreaInset` still reserves its
        // footprint so scrollable content stops clear of it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomNavBar(selection: $tab)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
    }
}
