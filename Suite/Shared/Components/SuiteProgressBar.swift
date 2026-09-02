import SwiftUI

/// Thin rounded progress bar — `track` capsule, amber fill.
/// Used once at the top of a card *and* per-row in breakdown lists (pass a
/// smaller `height` there, e.g. 8).
struct SuiteProgressBar: View {
    /// 0…1, clamped.
    var value: Double
    var height: CGFloat = Theme.Size.progressBar

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.track)
                Capsule()
                    .fill(Theme.Palette.accent)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}
