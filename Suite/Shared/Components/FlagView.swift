import SwiftUI

/// A country flag in the flat, rounded-rectangle style (Duolingo-like).
///
/// Artwork is flagpack (`Assets.xcassets/Flags/`, MIT) — one vector imageset
/// per ISO 3166-1 alpha-2 code the app lists — clipped to a rounded rect with
/// a hairline edge so light flags still read on a white background.
struct FlagView: View {
    /// ISO 3166-1 alpha-2 code, e.g. `"ES"`.
    let code: String
    /// Rendered height in points; width follows the flagpack 4:3 ratio.
    var height: CGFloat = 20

    private var width: CGFloat { (height * 4 / 3).rounded() }
    private var radius: CGFloat { height * 0.16 }

    var body: some View {
        Image("Flags/\(code.uppercased())")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
            )
            .accessibilityHidden(true)
    }
}
