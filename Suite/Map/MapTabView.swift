import SwiftUI
import SwiftData

/// 09 · Map tab — the world with visited countries filled amber and want-to-go
/// countries tinted. Tapping a country opens its sheet; the "+" opens the same
/// add-a-visit sheet the Passport uses, so it's one source of truth.
struct MapTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var visits: [VisitedPlace]
    @Query private var wishes: [WishlistPlace]
    @State private var showingAdd = false
    @State private var showingToggle = false
    @State private var showingLocation = false
    @State private var mode: MapViewMode = .countries
    @State private var selection: CountrySelection? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-openCountry"), i + 1 < a.count {
            return CountrySelection(iso: a[i + 1].uppercased())
        }
        return nil
    }()
    @State private var didApplyArgs = false

    private var visitedCodes: Set<String> { Set(visits.map { $0.countryCode.uppercased() }) }
    private var wishlistCodes: Set<String> { Set(wishes.map { $0.countryCode.uppercased() }) }

    var body: some View {
        ZStack {
            Color(hex: 0x0E1012).ignoresSafeArea()

            WorldMapView(visited: visitedCodes,
                         wishlist: wishlistCodes,
                         highlight: selection?.iso) { iso in
                selection = CountrySelection(iso: iso)
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button { showingLocation = true } label: {
                        SuiteIconView(icon: .mapPin, size: 20, color: Theme.Palette.textHeading)
                            .frame(width: 44, height: 44)
                            .background(Theme.Palette.surface.opacity(0.94), in: Circle())
                            .overlay(Circle().strokeBorder(Theme.Palette.border))
                    }
                    .accessibilityLabel("Centre on my location")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
                HStack(alignment: .bottom) {
                    Button { showingToggle = true } label: {
                        HStack(spacing: 10) {
                            LucideIcon(name: mode.iconName, size: 18, color: .white)
                            Text(mode.label)
                                .font(.archivo(14, .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.18)))
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                        .environment(\.colorScheme, .dark)   // dark frost over the always-dark map
                    }
                    .accessibilityLabel("Map display")
                    .accessibilityValue(mode.label)
                    .accessibilityHint("Switch between countries and cities")
                    Spacer()
                    Button { showingAdd = true } label: {
                        SuiteIconView(icon: .plus, size: 24, color: Theme.Palette.onAccent)
                            .frame(width: 56, height: 56)
                            .background(Theme.Palette.accent, in: Circle())
                            .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
                    }
                    .accessibilityLabel("Add a visited place")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .sheet(item: $selection) { CountryDetailView(iso: $0.iso) }
        .sheet(isPresented: $showingAdd) { AddVisitView() }
        .sheet(isPresented: $showingToggle) {
            MapViewToggleSheet(mode: $mode).presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showingLocation) {
            PermissionView(kind: .location) {}
        }
        .task {
            guard !didApplyArgs else { return }
            didApplyArgs = true
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-seedVisits") && visits.count < 3 {
                SampleData.seedVisitsDemo(into: context)
            }
            if args.contains("-seedWishlist") && wishes.isEmpty {
                for code in ["DZ", "JP", "BR", "IS", "NZ"] {
                    context.insert(WishlistPlace(countryName: Countries.name(for: code), countryCode: code))
                }
                try? context.save()
            }
            if args.contains("-mapAdd") { showingAdd = true }
            if args.contains("-mapToggle") { showingToggle = true }
        }
    }
}

struct CountrySelection: Identifiable, Equatable {
    let iso: String
    var id: String { iso }
}
