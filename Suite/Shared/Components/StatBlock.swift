import SwiftUI

/// A single stat: oversized amber number, optional smaller unit suffix in
/// primary, caption beneath. Never shown alone — pair it, or use `StatStrip`.
struct StatColumn: View {
    var value: String
    var unit: String? = nil
    var caption: String
    var valueSize: CGFloat = 40
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(value)
                    .font(.archivo(valueSize, .bold))
                    .tracking(valueSize * -0.03)
                    .foregroundStyle(Theme.Palette.accent)
                if let unit {
                    Text(unit)
                        .font(.archivo(valueSize * 0.6, .bold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                }
            }
            // Oversized display numbers shrink rather than wrap at large text sizes.
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            Text(caption)
                .font(.archivo(12))
                .foregroundStyle(Theme.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The Passport "In total" card: title, a left/right stat pair, an optional
/// progress bar and an optional mono caption.
struct StatBlock: View {
    var title: String
    var leading: StatColumn
    var trailing: StatColumn
    var progress: Double? = nil
    var caption: String? = nil

    var body: some View {
        SuiteCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.Suite.bodyStrong)
                    .foregroundStyle(Theme.Palette.textPrimary)

                HStack(alignment: .bottom) {
                    leading
                    Spacer(minLength: 12)
                    trailing
                }

                if let progress {
                    SuiteProgressBar(value: progress)
                }
                if let caption {
                    Text(caption)
                        .font(.Suite.labelS)
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Evenly spaced stat columns split by vertical hairlines — profile strip,
/// onboarding-tour stat rows.
struct StatStrip: View {
    var stats: [StatColumn]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.Palette.track)
                        .frame(width: 1, height: 34)
                }
                stat.frame(maxWidth: .infinity)
            }
        }
    }
}
