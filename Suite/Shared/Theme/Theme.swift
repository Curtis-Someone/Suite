import SwiftUI

/// Design tokens for Suite.
///
/// Values are pulled verbatim from the Claude Design handoff
/// (`Suite Screens Light.dc.html`, style-sheet artboard "12 · Style sheet").
/// `DESIGN_SYSTEM.md` at the repo root is the human-readable companion — keep
/// the two in sync. This file is the source of truth for code.
enum Theme {

    // MARK: Palette — light base, single amber accent

    enum Palette {
        /// App background (the "paper" ground behind every screen).
        static let ground        = Color(hex: 0xF5F3EF)
        /// Raised screen / primary surface.
        static let surface       = Color(hex: 0xFFFFFF)
        /// Inset card fill (stat cards, grouped settings rows).
        static let surfaceSunken = Color(hex: 0xF4F1EC)
        /// Onboarding-tour hero panel.
        static let panel         = Color(hex: 0xF1EEE8)
        /// Subtle fill (chips at rest, faint blocks).
        static let fill          = Color(hex: 0xEFEBE3)
        /// Slightly stronger fill (pressed chips, nav hairline zone).
        static let fillStrong    = Color(hex: 0xEAE6DF)

        /// Hairline border on white.
        static let border        = Color(hex: 0xE4E0D9)
        /// Divider inside a sunken card.
        static let divider       = Color(hex: 0xE2DED7)
        /// Progress-bar track / inactive toggle track.
        static let track         = Color(hex: 0xE0DCD4)

        static let accent        = Color(hex: 0xD09A42)
        /// Hover / pressed emphasis for the accent (links).
        static let accentHigh    = Color(hex: 0xE8B75F)
        /// Text / glyph colour on top of an amber fill.
        static let onAccent      = Color(hex: 0x0A0A0A)

        static let textPrimary   = Color(hex: 0x0A0A0A)
        /// Headings in dark UI chrome, icon strokes.
        static let textHeading   = Color(hex: 0x14161A)
        static let textBody      = Color(hex: 0x4A4740)
        static let textSecondary = Color(hex: 0x77736C)
        static let textTertiary  = Color(hex: 0x8F8B84)
        static let textDisabled  = Color(hex: 0xB4B0A8)

        /// Destructive actions ("Log out", "Delete account").
        static let danger        = Color(hex: 0xD96A4A)
    }

    // MARK: Corner radii

    enum Radius {
        static let control: CGFloat = 8    // swatches, tiny controls
        static let chip: CGFloat    = 16
        static let cardS: CGFloat   = 16
        static let card: CGFloat    = 20
        static let cardL: CGFloat   = 22
        static let fieldGroup: CGFloat = 18 // multi-row input group
        static let sheet: CGFloat   = 20   // bottom-sheet top corners
        /// The device frame radius used in the design canvas — reference only,
        /// not applied to real app views.
        static let deviceFrame: CGFloat = 46
    }

    // MARK: Spacing scale

    enum Space {
        static let xs: CGFloat  = 8
        static let s: CGFloat   = 12
        static let m: CGFloat   = 16
        static let l: CGFloat   = 20
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
        static let section: CGFloat = 44
        /// Default horizontal inset from a screen edge to its content.
        static let screenH: CGFloat = 24
    }

    // MARK: Component sizing

    enum Size {
        /// Full-width primary CTA height on a screen.
        static let cta: CGFloat        = 58
        /// Compact CTA (inside sheets / forms).
        static let ctaCompact: CGFloat = 54
        static let field: CGFloat      = 52
        static let navBar: CGFloat     = 78
        static let tabIcon: CGFloat    = 28
        /// Progress-bar thickness.
        static let progressBar: CGFloat = 10
    }

    // MARK: Icons

    enum Icon {
        /// The single, consistent line-icon stroke weight (`sw` in the canvas).
        static let stroke: CGFloat = 1.6
        static let sizeS: CGFloat  = 16
        static let sizeM: CGFloat  = 18   // inline with text
        static let sizeL: CGFloat  = 24   // standard
    }

    // Fonts (Archivo, JetBrains Mono) are bundled in Resources/Fonts and
    // registered via the `UIAppFonts` key in Info.plist — no code needed.
}
