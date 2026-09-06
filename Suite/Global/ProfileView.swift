import SwiftUI
import SwiftData

/// G1 · Profile — avatar, name, member-since, stat strip, menu, sign out.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var auth

    @Query private var settingsList: [UserSettings]
    @Query private var visits: [VisitedPlace]
    @Query private var trips: [Trip]

    @State private var showShare = false

    private var settings: UserSettings { settingsList.first ?? UserSettings.current(in: context) }
    private var name: String { settings.displayName.isEmpty ? "Traveller" : settings.displayName }
    private var initials: String {
        let parts = name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }
        return parts.joined().uppercased()
    }
    private var stats: PassportStats { PassportStats(visits: visits) }

    @State private var devPath: [String] = ProcessInfo.processInfo.arguments.contains("-openSettings") ? ["settings"] : []

    var body: some View {
        NavigationStack(path: $devPath) {
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().strokeBorder(Theme.Palette.border).frame(width: 42, height: 42))
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                    NavigationLink { SettingsView() } label: {
                        SuiteIconView(icon: .settings, size: 22, color: Theme.Palette.textHeading)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 14) {
                            Text(initials)
                                .font(.archivo(32, .bold))
                                .foregroundStyle(Theme.Palette.accent)
                                .frame(width: 96, height: 96)
                                .background(Theme.Palette.surfaceSunken, in: Circle())
                                .overlay(Circle().strokeBorder(Theme.Palette.accent, lineWidth: 1.6))
                            Text(name)
                                .font(.Suite.title).tracking(25 * -0.02)
                                .foregroundStyle(Theme.Palette.textPrimary)
                            Text("Member since \(memberSince)")
                                .font(.Suite.labelS).tracking(1.4).textCase(.uppercase)
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }
                        .padding(.top, 20)

                        StatStrip(stats: [
                            StatColumn(value: "\(stats.countryCount)", caption: "countries", valueSize: 26, alignment: .center),
                            StatColumn(value: "\(trips.count)", caption: "trips", valueSize: 26, alignment: .center),
                            StatColumn(value: "\(Int((stats.worldPercent * 100).rounded()))%", caption: "of world", valueSize: 26, alignment: .center),
                        ])
                        .padding(20)
                        .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: 20))

                        SuiteCard(padding: 4) {
                            VStack(spacing: 0) {
                                Button { showShare = true } label: { menuRow("Share my passport") }
                                    .buttonStyle(.suitePress)
                                Rectangle().fill(Theme.Palette.divider).frame(height: 1)
                                NavigationLink { SettingsView() } label: { menuRow("Settings") }
                                    .buttonStyle(.suitePress)
                            }
                        }

                        SuiteButton(title: auth.isSignedIn ? "Sign out" : "Sign in",
                                    style: .secondary, height: 54) {
                            if auth.isSignedIn { auth.signOut(context: context) }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(Theme.Palette.ground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { _ in SettingsView() }
        }
        .sheet(isPresented: $showShare) { ShareCardView() }
    }

    private func menuRow(_ title: String) -> some View {
        HStack {
            Text(title).font(.Suite.body).foregroundStyle(Theme.Palette.textHeading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            SuiteIconView(icon: .chevronRight, size: 15)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    private var memberSince: String {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"
        return f.string(from: settings.memberSince)
    }
}
