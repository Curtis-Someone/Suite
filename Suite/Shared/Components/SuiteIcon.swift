import SwiftUI

/// A **Lucide** icon by asset name (`Suite/Resources/Assets.xcassets/Lucide/`),
/// imported as a template SVG so it tints with `color` and scales cleanly.
/// One consistent stroke weight (~1.75 on a 24 grid), per CLAUDE.md.
///
/// Use `SuiteIcon` for the curated common glyphs; pass a raw `name` for the
/// long-tail (builder chips, weather codes).
struct LucideIcon: View {
    var name: String
    var size: CGFloat = Theme.Icon.sizeL
    var color: Color = Theme.Palette.textTertiary

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
            .accessibilityHidden(true)   // decorative; icon-only buttons label themselves
    }
}

/// Curated common icons. The bottom-nav tabs are tinted in code too — `map`
/// (Lucide) plus the custom `suitcase` / `passport` glyphs — see `BottomNavBar.swift`.
enum SuiteIcon: String {
    case chevronLeft   = "chevron-left"
    case chevronRight  = "chevron-right"
    case chevronDown   = "chevron-down"
    case chevronUp     = "chevron-up"
    case arrowLeft     = "arrow-left"

    case plus
    case circlePlus    = "circle-plus"
    case check
    case checkDouble   = "check-check"
    case circleCheck   = "circle-check"
    case close         = "x"

    case search
    case settings
    case bell
    case wifiOff       = "wifi-off"
    case mapPin        = "map-pin"
    case pin
    case ellipsis
    case calendar
    case pencil
    case pencilLine    = "pencil-line"
    case share         = "share-2"
    case filter        = "list-filter"
    case funnel
    case list
    case listPlus      = "list-plus"
    case user          = "circle-user"
    case users
    case heart
    case flag
    case globe
    case trash         = "trash-2"
    case info
    case bookOpen      = "book-open"
    case map
    case contact
    case luggage

    case sun
    case wind
    case snowflake
    case cloud
    case cloudRain     = "cloud-rain"
    case cloudSnow     = "cloud-snow"
    case cloudSunRain  = "cloud-sun-rain"
}

struct SuiteIconView: View {
    var icon: SuiteIcon
    var size: CGFloat = Theme.Icon.sizeL
    var color: Color = Theme.Palette.textTertiary

    var body: some View {
        LucideIcon(name: icon.rawValue, size: size, color: color)
    }
}
