import SwiftUI

/// The post-onboarding shell: three tabs behind the custom bottom nav.
/// Opens on Suitcase (the core loop).
struct MainAppShell: View {
    @Environment(\.modelContext) private var context

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
        // One screen at a time, switched by the bottom bar or a horizontal
        // finger-swipe between adjacent tabs. The swipe is disabled on the Map
        // tab — there every finger drag pans the map.
        Group {
            switch tab {
            case .map:      MapTabView()
            case .suitcase: SuitcaseTabView()
            case .passport: PassportTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(tab == .map ? nil : tabSwipe)
        // The pill is a pure overlay — it reserves no layout space, so the tab
        // content runs full-bleed to the screen edge and scrolls *behind* it
        // (each tab already pads its own content clear of the pill).
        .overlay(alignment: .bottom) {
            BottomNavBar(selection: $tab)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .task { TripVisitSync.run(context: context) }
    }

    /// Horizontal swipe between adjacent tabs: drag left for the next tab,
    /// right for the previous. Low-priority so vertical scrolling and taps
    /// inside the tab still win; only a clearly horizontal throw switches tabs.
    private var tabSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > 60, abs(dx) > abs(value.translation.height) * 1.4 else { return }
                let tabs = SuiteTab.allCases          // [.map, .suitcase, .passport]
                guard let i = tabs.firstIndex(of: tab) else { return }
                let target = dx < 0 ? i + 1 : i - 1
                guard tabs.indices.contains(target) else { return }
                withAnimation(.snappy(duration: 0.28)) { tab = tabs[target] }
            }
    }
}
