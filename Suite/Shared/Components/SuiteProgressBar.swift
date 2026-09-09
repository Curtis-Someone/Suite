import SwiftUI

/// Thin rounded progress bar — `track` capsule, amber fill.
/// Used once at the top of a card *and* per-row in breakdown lists (pass a
/// smaller `height` there, e.g. 8).
struct SuiteProgressBar: View {
    /// 0…1, clamped.
    var value: Double
    var height: CGFloat = Theme.Size.progressBar

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.track)
                Capsule()
                    .fill(Theme.Palette.accent)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
                    // Glide to the new length when items get checked, rather
                    // than jumping. Instant under Reduce Motion.
                    .animation(Theme.Motion.settle.gated(reduceMotion), value: value)
            }
        }
        .frame(height: height)
    }
}
