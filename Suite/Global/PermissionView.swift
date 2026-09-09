import SwiftUI
import UserNotifications
import CoreLocation

/// A3 · Location permission and A4 · Notification permission — same layout.
struct PermissionView: View {
    enum Kind { case location, notifications }

    var kind: Kind
    var onDecided: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Circle()
                .strokeBorder(Theme.Palette.track, lineWidth: 1.6)
                .frame(width: 132, height: 132)
                .overlay(LucideIcon(name: iconName, size: 58, color: Theme.Palette.accent))
            Spacer().frame(height: 38)
            Text(headline)
                .font(.Suite.titleXL).tracking(30 * -0.02)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer().frame(height: 16)
            Text(message)
                .font(.Suite.bodyL)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.Palette.textSecondary)
            Spacer()
            SuiteButton(title: allowTitle) { request() }
            Button("Not now") { finish() }
                .font(.archivo(14, .semibold))
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 22)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.surface.ignoresSafeArea())
    }

    private func request() {
        switch kind {
        case .notifications:
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                    Task { @MainActor in finish() }
                }
        case .location:
            CLLocationManager().requestWhenInUseAuthorization()
            finish()
        }
    }

    private func finish() {
        onDecided()
        dismiss()
    }

    private var iconName: String { kind == .location ? "map-pin" : "bell" }
    private var headline: String {
        kind == .location ? "See your travels\ncome to life." : "Never pack\nat 2am again."
    }
    private var message: String {
        kind == .location
            ? "With location on, Suite fills in countries and cities as you move through them."
            : "A nudge two days before each trip, with whatever is still unpacked."
    }
    private var allowTitle: String {
        kind == .location ? "Allow location" : "Enable notifications"
    }
}
