import SwiftUI

/// Type ramp for Suite.
///
/// Two families only:
/// - **Archivo** — display, UI, headings, body copy, *and* the oversized hero
///   stat numbers.
/// - **JetBrains Mono** — kicker labels and small tabular data (fractions, `%`).
///
/// Note on the "numbers are always monospaced" rule from `CLAUDE.md`: the
/// handoff overrides it for the *big* hero stat numbers, which are set in
/// Archivo (see the style-sheet artboard). Small inline data stays mono.
extension Font {

    /// Custom face that still scales with the system text-size setting.
    /// `relativeTo` anchors the growth curve to a system text style — pass the
    /// closest one for the role (`.largeTitle` for hero numbers, `.caption2` for
    /// kickers). Defaults to `.body` so ad-hoc call sites scale too.
    static func archivo(_ size: CGFloat, _ weight: Font.Weight = .regular,
                        relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Archivo", size: size, relativeTo: style).weight(weight)
    }

    static func jetBrainsMono(_ size: CGFloat, _ weight: Font.Weight = .regular,
                              relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("JetBrains Mono", size: size, relativeTo: style).weight(weight)
    }

    enum Suite {
        /// Wordmark "Suite." — pair with `.tracking(size * -0.03)`.
        static let display    = Font.archivo(40, .heavy, relativeTo: .largeTitle)
        /// Hero stat number (amber); the unit suffix drops to ~24pt / primary.
        static let statXL     = Font.archivo(40, .bold, relativeTo: .largeTitle)
        static let statL      = Font.archivo(30, .bold, relativeTo: .title)
        static let statM      = Font.archivo(26, .bold, relativeTo: .title)

        static let titleXL    = Font.archivo(30, .bold, relativeTo: .largeTitle)  // screen title, 2 lines
        static let titleL     = Font.archivo(27, .bold, relativeTo: .title)
        static let title      = Font.archivo(25, .bold, relativeTo: .title)
        static let titleS     = Font.archivo(22, .bold, relativeTo: .title2)      // section header

        static let button     = Font.archivo(17, .bold, relativeTo: .headline)
        static let bodyL      = Font.archivo(15, .regular, relativeTo: .body)     // 1.55 line height
        static let body       = Font.archivo(15, .regular, relativeTo: .body)
        static let bodyStrong = Font.archivo(15, .semibold, relativeTo: .body)
        static let bodyS      = Font.archivo(13, .regular, relativeTo: .subheadline)

        /// Tabular data — fractions, percentages.
        static let data       = Font.jetBrainsMono(12, .regular, relativeTo: .caption)
        /// Kicker label — pair with `.tracking(1.6)` + `.textCase(.uppercase)`.
        static let label      = Font.jetBrainsMono(11, .medium, relativeTo: .caption2)
        static let labelS     = Font.jetBrainsMono(10, .regular, relativeTo: .caption2)
        static let micro      = Font.jetBrainsMono(9, .regular, relativeTo: .caption2)
    }
}

/// The Suite wordmark: "Suite" in `wordColor` + an amber full stop.
struct Wordmark: View {
    var size: CGFloat = 26
    var wordColor: Color = Theme.Palette.textPrimary

    var body: some View {
        HStack(spacing: 0) {
            Text("Suite").foregroundStyle(wordColor)
            Text(".").foregroundStyle(Theme.Palette.accent)
        }
        .font(.archivo(size, .heavy))
        .tracking(size * -0.03)
    }
}
