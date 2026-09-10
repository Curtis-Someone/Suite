import SwiftUI
import SwiftData

/// The post-onboarding shell: three tabs behind the custom bottom nav.
/// Opens on Suitcase (the core loop).
struct MainAppShell: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    private let entitlements = Entitlements.shared

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

    @State private var showingNewTrip = false
    @State private var showingNewPlace = false
    @State private var showingNewFriend = false
    @State private var upsell: UpsellMoment?

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
        // The dock is a pure overlay — it reserves no layout space, so the tab
        // content runs full-bleed to the screen edge and scrolls *behind* it
        // (each tab already pads its own content clear of the pill).
        .overlay(alignment: .bottom) {
            BottomNavBar(
                selection: $tab,
                onNewTrip: newTripTapped,
                onNewPlace: { showingNewPlace = true },
                onNewFriend: newFriendTapped
            )
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingNewTrip) {
            NewTripFlow { _ in tab = .suitcase }
        }
        .sheet(isPresented: $showingNewPlace) { AddVisitView() }
        .fullScreenCover(isPresented: $showingNewFriend) { AddFriendsView() }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .task { TripVisitSync.run(context: context) }
    }

    /// New trip from the quick-add menu — same free-tier gate as the Suitcase tab.
    private func newTripTapped() {
        switch PackingGate.canCreateTrip(existingTrips: trips, isPro: entitlements.isPro) {
        case .allowed:             showingNewTrip = true
        case .blocked(let reason): upsell = reason
        }
    }

    /// New friend from the quick-add menu — Friends is Pro-gated.
    private func newFriendTapped() {
        switch PackingGate.canUseFriends(isPro: entitlements.isPro) {
        case .allowed:             showingNewFriend = true
        case .blocked(let reason): upsell = reason
        }
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
