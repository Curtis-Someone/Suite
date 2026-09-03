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

    static func archivo(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Archivo", size: size).weight(weight)
    }

    static func jetBrainsMono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("JetBrains Mono", size: size).weight(weight)
    }

    enum Suite {
        /// Wordmark "Suite." — pair with `.tracking(size * -0.03)`.
        static let display    = Font.archivo(40, .heavy)
        /// Hero stat number (amber); the unit suffix drops to ~24pt / primary.
        static let statXL     = Font.archivo(40, .bold)
        static let statL      = Font.archivo(30, .bold)
        static let statM      = Font.archivo(26, .bold)

        static let titleXL    = Font.archivo(30, .bold)   // screen title, 2 lines
        static let titleL     = Font.archivo(27, .bold)
        static let title      = Font.archivo(25, .bold)
        static let titleS     = Font.archivo(22, .bold)   // section header

        static let button     = Font.archivo(17, .bold)
        static let bodyL      = Font.archivo(15, .regular) // 1.55 line height
        static let body       = Font.archivo(15, .regular)
        static let bodyStrong = Font.archivo(15, .semibold)
        static let bodyS      = Font.archivo(13, .regular)

        /// Tabular data — fractions, percentages.
        static let data       = Font.jetBrainsMono(12, .regular)
        /// Kicker label — pair with `.tracking(1.6)` + `.textCase(.uppercase)`.
        static let label      = Font.jetBrainsMono(11, .medium)
        static let labelS     = Font.jetBrainsMono(10, .regular)
        static let micro      = Font.jetBrainsMono(9, .regular)
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
