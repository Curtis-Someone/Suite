import SwiftUI
import SwiftData

/// 09 · Map tab — the world with visited countries filled amber and want-to-go
/// countries tinted. Tapping a country opens its sheet; the "+" opens the same
/// add-a-visit sheet the Passport uses, so it's one source of truth.
struct MapTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var visits: [VisitedPlace]
    @Query private var wishes: [WishlistPlace]
    @Query private var friends: [Friend]
    @Query private var settingsList: [UserSettings]
    @State private var showingAdd = false
    @State private var showingToggle = false
    @State private var showingLocation = false
    @State private var showingWhoseMap = false
    @State private var viewingFriend: Friend?
    @State private var mode: MapViewMode = .countries
    @State private var selection: CountrySelection? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-openCountry"), i + 1 < a.count {
            return CountrySelection(iso: a[i + 1].uppercased())
        }
        return nil
    }()
    @State private var didApplyArgs = false

    private var ownVisitedCodes: Set<String> { Set(visits.map { $0.countryCode.uppercased() }) }
    private var visitedCodes: Set<String> {
        if let friend = viewingFriend { return Set(friend.countryCodes.map { $0.uppercased() }) }
        return ownVisitedCodes
    }
    private var wishlistCodes: Set<String> {
        viewingFriend == nil ? Set(wishes.map { $0.countryCode.uppercased() }) : []
    }
    private var mapFriends: [Friend] { friends.accepted.filter(\.sharesPassport) }
    private var myName: String { settingsList.first?.displayName ?? "" }

    var body: some View {
        ZStack {
            Color(light: 0xFFFFFF, dark: 0x0E1012).ignoresSafeArea()

            WorldMapView(visited: visitedCodes,
                         wishlist: wishlistCodes,
                         highlight: selection?.iso) { iso in
                selection = CountrySelection(iso: iso)
            }
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 10) {
                    if !mapFriends.isEmpty {
                        Button {
                            if viewingFriend == nil { showingWhoseMap = true } else { viewingFriend = nil }
                        } label: {
                            HStack(spacing: 8) {
                                LucideIcon(name: "users", size: 16, color: Theme.Palette.textHeading)
                                Text(viewingFriend == nil ? "Whose map?" : "Viewing \(possessive(viewingFriend!.displayName)) map")
                                    .font(.archivo(13, .semibold))
                                    .foregroundStyle(Theme.Palette.textHeading)
                                    .lineLimit(1)
                                if viewingFriend != nil {
                                    SuiteIconView(icon: .close, size: 13, color: Theme.Palette.textSecondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(
                                viewingFriend == nil ? Theme.Palette.border : Theme.Palette.accent,
                                lineWidth: viewingFriend == nil ? 1 : 1.6))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(viewingFriend == nil ? "Choose whose map to view" : "Back to your map")
                    }
                    Spacer()
                    Button { showingLocation = true } label: {
                        SuiteIconView(icon: .mapPin, size: 20, color: Theme.Palette.textHeading)
                            .frame(width: 44, height: 44)
                            .background(Theme.Palette.surface.opacity(0.94), in: Circle())
                            .overlay(Circle().strokeBorder(Theme.Palette.border))
                    }
                    .accessibilityLabel("Fill in my location")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
                HStack(alignment: .bottom) {
                    Button { showingToggle = true } label: {
                        HStack(spacing: 10) {
                            LucideIcon(name: mode.iconName, size: 18, color: Theme.Palette.textHeading)
                            Text(mode.label)
                                .font(.archivo(14, .semibold))
                                .foregroundStyle(Theme.Palette.textHeading)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.Palette.border))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                    }
                    Spacer()
                    Button { showingAdd = true } label: {
                        SuiteIconView(icon: .plus, size: 24, color: Theme.Palette.onAccent)
                            .frame(width: 56, height: 56)
                            .background(Theme.Palette.accent, in: Circle())
                            .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
                    }
                    .accessibilityLabel("Add a place you've visited")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, Theme.Size.navPillClearance)
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
        .sheet(isPresented: $showingWhoseMap) {
            WhoseMapSheet(myName: myName, friends: mapFriends, selected: viewingFriend) { viewingFriend = $0 }
                .presentationDetents([.height(min(320, CGFloat(160 + mapFriends.count * 62)))])
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

/// "Maria" → "Maria's", "Lucas" → "Lucas'".
func possessive(_ name: String) -> String {
    let first = name.split(separator: " ").first.map(String.init) ?? name
    return first.hasSuffix("s") ? "\(first)'" : "\(first)'s"
}
