import SwiftUI
import SwiftData

/// G2 · Settings — grouped preferences.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var auth
    private let entitlements = Entitlements.shared

    @Query private var settingsList: [UserSettings]
    @State private var askNotifications = false
    @State private var confirmSignOut = false
    @State private var confirmDeleteAccount = false
    @State private var showPro = false
    @State private var showDataExport = false
    @State private var upsell: UpsellMoment?

    private var settings: UserSettings { settingsList.first ?? UserSettings.current(in: context) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                .accessibilityLabel("Back")
                Text("Settings")
                    .font(.Suite.title).tracking(25 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    proRow

                    group("Account") {
                        navRow("Apple ID", value: auth.isSignedIn ? (settings.displayName.isEmpty ? "Signed in" : settings.displayName) : "Not signed in")
                        divider
                        Button { confirmDeleteAccount = true } label: {
                            navRow("Delete account", tint: Theme.Palette.danger)
                        }
                        .buttonStyle(.plain)
                    }

                    group("Preferences") {
                        HStack {
                            Text("Units").font(.Suite.body).foregroundStyle(Theme.Palette.textHeading)
                            Spacer()
                            SegmentedToggle(
                                options: [(UnitsPreference.metric, "Metric"), (UnitsPreference.imperial, "Imperial")],
                                selection: Binding(
                                    get: { settings.unitsPreference },
                                    set: { settings.unitsPreference = $0; save() }),
                                height: 34
                            )
                            .frame(width: 190)
                        }
                        .frame(height: 56)
                        divider
                        toggleRow("Packing reminders", isOn: Binding(
                            get: { settings.packingReminders },
                            set: { on in
                                settings.packingReminders = on; save()
                                if on { askNotifications = true }
                            }))
                        divider
                        toggleRow("Trip recaps", isOn: Binding(
                            get: { settings.tripRecaps },
                            set: { settings.tripRecaps = $0; save() }))
                    }

                    group("Data") {
                        Button { exportTapped() } label: {
                            navRow("Export your data", value: entitlements.isPro ? nil : "Pro")
                        }
                        .buttonStyle(.plain)
                    }

                    if auth.isSignedIn {
                        SuiteCard {
                            Button { confirmSignOut = true } label: {
                                Text("Log out")
                                    .font(.Suite.bodyStrong)
                                    .foregroundStyle(Theme.Palette.danger)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 24)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $askNotifications) {
            PermissionView(kind: .notifications) {}
        }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .sheet(isPresented: $showDataExport) { DataExportSheet() }
        .fullScreenCover(isPresented: $showPro) { ProBenefitsView() }
        .confirmationDialog("Log out of Suite?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Log out", role: .destructive) { auth.signOut(context: context) }
        }
        .alert("Delete Account", isPresented: $confirmDeleteAccount) {
            Button("Delete Account", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes all your trips, suitcases, packing lists and visited places from this device, and signs you out. This can't be undone.")
        }
    }

    /// H-01 · Guideline 5.1.1(v) — in-app account deletion. Wipes every local
    /// record, clears the stored Apple identity, and drops back to onboarding.
    private func deleteAccount() {
        let models: [any PersistentModel.Type] = [
            Trip.self, Suitcase.self, Item.self,
            Template.self, TemplateItem.self,
            Traveler.self, WeatherDay.self,
            VisitedPlace.self, WishlistPlace.self, UserSettings.self,
        ]
        for model in models { try? context.delete(model: model) }
        try? context.save()
        // TODO: once iCloud sync ships, also delete the user's CloudKit records.
        auth.signOut(context: context)   // recreates a virgin UserSettings row
    }

    private func exportTapped() {
        switch PackingGate.canExport(isPro: entitlements.isPro) {
        case .allowed:             showDataExport = true
        case .blocked(let reason): upsell = reason
        }
    }

    @ViewBuilder
    private var proRow: some View {
        if entitlements.isPro {
            SuiteCard(padding: 18) {
                HStack {
                    LucideIcon(name: "gem", size: 18, color: Theme.Palette.accent)
                    Text("Suite Pro").font(.Suite.body).foregroundStyle(Theme.Palette.textHeading)
                    Spacer()
                    Text("Active").font(.jetBrainsMono(11, .bold))
                        .foregroundStyle(Theme.Palette.accent)
                }
            }
        } else {
            Button { showPro = true } label: {
                SuiteCard(padding: 18) {
                    HStack(spacing: 12) {
                        LucideIcon(name: "gem", size: 20, color: Theme.Palette.onAccent)
                            .frame(width: 40, height: 40)
                            .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Suite Pro")
                                .font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textHeading)
                            Text("Unlimited trips, templates, export and more")
                                .font(.archivo(12)).foregroundStyle(Theme.Palette.textSecondary)
                        }
                        Spacer()
                        SuiteIconView(icon: .chevronRight, size: 15)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: rows

    @ViewBuilder
    private func group<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KickerLabel(title)
            SuiteCard(padding: 18) { VStack(spacing: 0) { content() } }
        }
    }

    private func navRow(_ title: String, value: String? = nil, tint: Color = Theme.Palette.textHeading) -> some View {
        HStack {
            Text(title).font(.Suite.body).foregroundStyle(tint)
            Spacer()
            if let value {
                Text(value).font(.archivo(13)).foregroundStyle(Theme.Palette.textTertiary)
            }
            SuiteIconView(icon: .chevronRight, size: 15)
        }
        .frame(height: 52)
        .contentShape(Rectangle())
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.Suite.body).foregroundStyle(Theme.Palette.textHeading)
            Spacer()
            SuiteSwitch(isOn: isOn)
        }
        .frame(height: 56)
    }

    private var divider: some View { Rectangle().fill(Theme.Palette.divider).frame(height: 1) }

    private func save() { try? context.save() }
}
