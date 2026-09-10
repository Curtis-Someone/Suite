import SwiftUI
import SwiftData

@main
struct SuiteApp: App {
    @State private var auth = AuthService()
    @State private var entitlements = Entitlements.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(entitlements)
                .task { await entitlements.start() }
        }
        .modelContainer(for: [
            Trip.self, Suitcase.self, Item.self,
            Template.self, TemplateItem.self,
            Traveler.self, WeatherDay.self, Friend.self,
            VisitedPlace.self, WishlistPlace.self, UserSettings.self,
        ])
    }
}
