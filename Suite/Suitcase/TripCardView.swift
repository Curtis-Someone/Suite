import SwiftUI

/// S1 trip card — icon tile, name, countdown, dates · country, readiness bar.
struct TripCardView: View {
    let trip: Trip

    private var suitcase: Suitcase? { trip.suitcases.first }
    private var isPast: Bool { trip.isArchived || trip.status == .past }
    private var progress: Double { suitcase?.progress ?? 0.18 }
    private var packed: Int { suitcase?.items.filter(\.isPacked).count ?? 0 }
    private var total: Int { suitcase?.items.count ?? 0 }

    var body: some View {
        HStack(spacing: 14) {
            LucideIcon(name: trip.iconName, size: 28,
                       color: isPast ? Theme.Palette.textSecondary : Theme.Palette.onAccent)
                .frame(width: 64, height: 64)
                .background(isPast ? Theme.Palette.track : Theme.Palette.accent,
                           in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(trip.name)
                        .font(.archivo(17, .bold)).tracking(-0.17)
                        .foregroundStyle(isPast ? Theme.Palette.textBody : Theme.Palette.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    if isPast {
                        Text("Done")
                            .font(.jetBrainsMono(10, .medium)).tracking(0.8).textCase(.uppercase)
                            .foregroundStyle(Theme.Palette.textSecondary)
                            .padding(.horizontal, 9).frame(height: 22)
                            .background(Theme.Palette.fillStrong, in: Capsule())
                    } else {
                        Text(countdown)
                            .font(.jetBrainsMono(11))
                            .foregroundStyle(Theme.Palette.accent)
                    }
                }
                Text("\(dateRange) · \(trip.destinationCountry)")
                    .font(.jetBrainsMono(12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .lineLimit(1)

                SuiteProgressBar(value: isPast ? 1 : progress, height: 7)

                Text(isPast ? "\(packed)/\(total) packed" : "\(Int((progress * 100).rounded()))% ready · \(packed)/\(total)")
                    .font(.jetBrainsMono(11))
                    .foregroundStyle(isPast ? Theme.Palette.textTertiary : Theme.Palette.textBody)
            }
        }
        .padding(16)
        .background(isPast ? Theme.Palette.panel : Theme.Palette.surfaceSunken,
                   in: RoundedRectangle(cornerRadius: 20))
    }

    private var dateRange: String {
        "\(PackingChecklistView.dateRange(trip)) \(Calendar.current.component(.year, from: trip.endDate))"
    }

    private var countdown: String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: trip.startDate).day ?? 0
        if days > 1 { return "in \(days)d" }
        if days == 1 { return "tomorrow" }
        if days == 0 { return "today" }
        return "now"
    }
}
