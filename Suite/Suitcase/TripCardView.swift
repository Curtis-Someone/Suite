import SwiftUI

/// S1 trip card — icon tile, name, countdown, dates · country, readiness bar.
struct TripCardView: View {
    let trip: Trip

    private var isPast: Bool { trip.isArchived || trip.status == .past }
    /// A trip can hold several bags now — show the trip's overall readiness.
    private var bags: [Suitcase] { trip.suitcases }
    private var items: [Item] { bags.flatMap(\.items) }
    private var progress: Double {
        guard !bags.isEmpty else { return 0 }
        return bags.map(\.progress).reduce(0, +) / Double(bags.count)
    }
    private var packed: Int { items.filter(\.isPacked).count }
    private var total: Int { items.count }

    var body: some View {
        HStack(spacing: 14) {
            LucideIcon(name: trip.iconName, size: 28,
                       color: isPast ? Theme.Palette.textSecondary : Theme.Palette.onAccent)
                .frame(width: 64, height: 64)
                .background(isPast ? Theme.Palette.track : Theme.Palette.accent,
                           in: RoundedRectangle(cornerRadius: Theme.Radius.chip))

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

                Text(statusLine)
                    .font(.jetBrainsMono(11))
                    .foregroundStyle(isPast ? Theme.Palette.textTertiary : Theme.Palette.textBody)
            }
        }
        .padding(16)
        .background(isPast ? Theme.Palette.panel : Theme.Palette.surfaceSunken,
                   in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var statusLine: String {
        guard !bags.isEmpty else { return isPast ? "No packing list" : "No suitcase yet" }
        let tail = bags.count > 1 ? " · \(bags.count) bags" : ""
        if isPast { return "\(packed)/\(total) packed\(tail)" }
        return "\(Int((progress * 100).rounded()))% ready · \(packed)/\(total)\(tail)"
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
