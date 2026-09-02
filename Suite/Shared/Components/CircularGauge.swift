import SwiftUI

/// Amber progress ring on a `track` ring, big number centred.
/// Defaults match the style-sheet spec (96 pt, 11 pt ring, 21 pt number);
/// the "setting up" screen overrides these for its 190 pt version.
struct CircularGauge: View {
    /// 0…1, clamped.
    var value: Double
    var size: CGFloat = 96
    var ringWidth: CGFloat = 11
    /// Defaults to the rounded percentage.
    var label: String? = nil

    private var clamped: Double { max(0, min(1, value)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Palette.track, lineWidth: ringWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Theme.Palette.accent,
                        style: StrokeStyle(lineWidth: ringWidth,
                                           lineCap: clamped >= 1 ? .butt : .round))
                .rotationEffect(.degrees(-90))

            Text(label ?? "\(Int((clamped * 100).rounded()))%")
                .font(.archivo(size * 0.22, .bold))
                .tracking(size * 0.22 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
        }
        .frame(width: size, height: size)
    }
}
