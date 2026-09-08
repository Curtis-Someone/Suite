import SwiftUI

/// Design tokens for Suite.
///
/// Values are pulled verbatim from the Claude Design handoff
/// (`Suite Screens Light.dc.html`, style-sheet artboard "12 · Style sheet").
/// `DESIGN_SYSTEM.md` at the repo root is the human-readable companion — keep
/// the two in sync. This file is the source of truth for code.
enum Theme {

    // MARK: Palette — light base, single amber accent

    /// Light values from `Suite Screens Light.dc.html`, dark from
    /// `Suite Screens.dc.html`. The app follows the system appearance (default
    /// light). Dark shades are calibrated from the dark style-sheet artboard and
    /// refined per screen as batches build against the dark artboards.
    enum Palette {
        /// App background (the "paper" ground behind every screen).
        static let ground        = Color(light: 0xF5F3EF, dark: 0x0F0F10)
        /// Raised screen / primary surface.
        static let surface       = Color(light: 0xFFFFFF, dark: 0x141415)
        /// Inset card fill (stat cards, grouped settings rows).
        static let surfaceSunken = Color(light: 0xF4F1EC, dark: 0x1A1A1B)
        /// Onboarding-tour hero panel.
        static let panel         = Color(light: 0xF1EEE8, dark: 0x1A1A1B)
        /// Subtle fill (chips at rest, faint blocks).
        static let fill          = Color(light: 0xEFEBE3, dark: 0x1F1F20)
        /// Slightly stronger fill (pressed chips, nav hairline zone).
        static let fillStrong    = Color(light: 0xEAE6DF, dark: 0x232325)

        /// Hairline border.
        static let border        = Color(light: 0xE4E0D9, dark: 0x232323)
        /// Divider inside a sunken card.
        static let divider       = Color(light: 0xE2DED7, dark: 0x2A2A2C)
        /// Progress-bar track / inactive toggle track.
        static let track         = Color(light: 0xE0DCD4, dark: 0x2E2E30)

        static let accent        = Color(hex: 0xD09A42)
        /// Hover / pressed emphasis for the accent (links).
        static let accentHigh    = Color(hex: 0xE8B75F)
        /// Text / glyph colour on top of an amber fill (amber works in both modes).
        static let onAccent      = Color(hex: 0x0A0A0A)

        static let textPrimary   = Color(light: 0x0A0A0A, dark: 0xFFFFFF)
        /// Headings in dark UI chrome, icon strokes.
        static let textHeading   = Color(light: 0x14161A, dark: 0xF2F0EC)
        static let textBody      = Color(light: 0x4A4740, dark: 0xC9C4BC)
        static let textSecondary = Color(light: 0x77736C, dark: 0x8A857E)
        static let textTertiary  = Color(light: 0x8F8B84, dark: 0x6E6A64)
        static let textDisabled  = Color(light: 0xB4B0A8, dark: 0x57534D)

        /// Destructive actions ("Log out", "Delete account").
        static let danger        = Color(light: 0xD96A4A, dark: 0xE07C5C)

        // MARK: Floating nav pill
        //
        // Dedicated colour sets in `Assets.xcassets` (not `Color(light:dark:)`
        // literals) so the v1.1 dark theme is a catalog edit, not new code.

        /// Near-black `#14161A` — inactive tab glyphs, and the neutral
        /// (colour-independent) highlight behind the active tab.
        static let navInk        = Color("NavInk")
        /// Text-safe amber `#97651B` — active tab icon + label. Darker and more
        /// saturated than `accent`, which fails contrast at this size on the
        /// cream ground (navAmber measures ~4.5:1 vs `ground` #F5F3EF; brand
        /// amber only ~2.9:1).
        static let navAmber      = Color("NavAmber")
        /// Brand amber `#D09A42` catalog alias — large fills / icons / display
        /// numerals only. Same value as `accent`; kept as a colour set so the
        /// three pill colours live together in the catalog.
        static let brandAmber    = Color("BrandAmber")
        /// Low-opacity near-black wash behind the active tab item — structural,
        /// not colour-signalled.
        static let navHighlight  = Color("NavInk").opacity(0.08)
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
        /// Bottom nav — height of the tab row (excludes the home-indicator inset).
        static let navPill: CGFloat    = 56
        static let tabIcon: CGFloat    = 28
        /// Progress-bar thickness.
        static let progressBar: CGFloat = 10
    }

    // MARK: Icons

    enum Icon {
        /// The single, consistent line-icon stroke weight (`sw` in the canvas).
        static let stroke: CGFloat = 1.75
        static let sizeS: CGFloat  = 16
        static let sizeM: CGFloat  = 18   // inline with text
        static let sizeL: CGFloat  = 24   // standard
    }

    // Fonts (Archivo, JetBrains Mono) are bundled in Resources/Fonts and
    // registered via the `UIAppFonts` key in Info.plist — no code needed.
}
