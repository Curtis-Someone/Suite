import SwiftUI

/// Guest passport view — a friend's stamps, read-only. Same stat block and
/// country layout as the Passport tab, but with an amber-underlined header so
/// it never reads as your own, and no edit / settings affordances.
///
/// Locked variant: shown when the friend hasn't turned passport sharing on for
/// you — a blurred stamp grid and one line.
struct FriendProfileView: View {
    let friend: Friend

    @Environment(\.dismiss) private var dismiss

    private var stamps: [Country] {
        Set(friend.countryCodes.map { $0.uppercased() })
            .intersection(Countries.codes)
            .compactMap { code in Countries.all.first { $0.code == code } }
            .sorted { $0.name < $1.name }
    }

    private var sharedTrips: [SharedTripInfo] { friend.sharedTrips }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 14) {
                    if friend.sharesPassport {
                        statCard
                        stampGrid
                        if !sharedTrips.isEmpty { tripsTogether }
                    } else {
                        lockedState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                .accessibilityLabel("Back")
                Spacer()
            }

            VStack(spacing: 6) {
                Text("\(possessive(friend.displayName)) Passport")
                    .font(.Suite.titleL).tracking(27 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Rectangle().fill(Theme.Palette.accent)
                    .frame(width: 44, height: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: Visible

    private var statCard: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("In total").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                HStack(alignment: .bottom) {
                    StatColumn(value: "\(friend.countryCount)", unit: " / 195", caption: "countries")
                    Spacer(minLength: 12)
                    StatColumn(value: "\(Int((friend.worldPercent * 100).rounded()))", unit: "%",
                               caption: "of the world", alignment: .trailing)
                }
                SuiteProgressBar(value: friend.worldPercent)
                Text("\(friend.cityCount) \(friend.cityCount == 1 ? "city" : "cities") stamped")
                    .font(.Suite.labelS)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var stampGrid: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Stamps").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                          spacing: 12) {
                    ForEach(stamps, id: \.code) { country in
                        VStack(spacing: 6) {
                            FlagView(code: country.code, height: 26)
                            Text(country.code)
                                .font(.Suite.micro)
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var tripsTogether: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 13) {
                Text("Trips together").font(.Suite.bodyStrong).foregroundStyle(Theme.Palette.textPrimary)
                ForEach(sharedTrips) { trip in
                    HStack(spacing: 12) {
                        FlagView(code: trip.countryCode, height: 21)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trip.destination)
                                .font(.archivo(14, .medium))
                                .foregroundStyle(Theme.Palette.textHeading)
                            Text(trip.dateRange)
                                .font(.jetBrainsMono(11))
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: Locked

    private var lockedState: some View {
        SuiteCard(padding: 24) {
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                          spacing: 12) {
                    ForEach(0..<12, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                            .fill(Theme.Palette.fill)
                            .frame(height: 34)
                    }
                }
                .blur(radius: 5)
                .overlay(
                    LucideIcon(name: "globe-lock", size: 26, color: Theme.Palette.textTertiary)
                )
                .accessibilityHidden(true)

                Text("\(friend.displayName) hasn't shared their passport yet.")
                    .font(.Suite.bodyS)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
    }

    private func possessive(_ name: String) -> String {
        let first = name.split(separator: " ").first.map(String.init) ?? name
        return first.hasSuffix("s") ? "\(first)'" : "\(first)'s"
    }
}
