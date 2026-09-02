import SwiftUI

/// Monochrome line icons, one consistent stroke weight.
///
/// The handoff draws Lucide-equivalent paths on a 24 view-box at stroke ≈1.6.
/// Where an SF Symbol matches the Lucide glyph 1:1 we use it (rendered at a
/// matched weight); the few glyphs SF lacks are drawn as `Path`s below.
/// Full-colour category / flag icons are a separate concern — not this type.
enum SuiteIcon {
    case chevronRight, chevronLeft
    case plus, check, xmark
    case search, gear, bell, mapPin, ellipsis, calendar, pencil, share

    /// SF Symbol name, or `nil` when we draw it ourselves.
    fileprivate var systemName: String? {
        switch self {
        case .chevronRight: "chevron.right"
        case .chevronLeft:  "chevron.left"
        case .search:       "magnifyingglass"
        case .gear:         "gearshape"
        case .bell:         "bell"
        case .mapPin:       "mappin"
        case .ellipsis:     "ellipsis"
        case .calendar:     "calendar"
        case .pencil:       "pencil"
        case .share:        "square.and.arrow.up"
        case .plus, .check, .xmark: nil
        }
    }
}

struct SuiteIconView: View {
    var icon: SuiteIcon
    var size: CGFloat = Theme.Icon.sizeL
    var color: Color = Theme.Palette.textTertiary
    /// Chevrons in the handoff read heavier than the body line weight.
    var weight: Font.Weight = .regular

    var body: some View {
        Group {
            if let name = icon.systemName {
                Image(systemName: name)
                    .font(.system(size: size * 0.82, weight: weight))
            } else {
                DrawnGlyph(icon: icon, size: size)
            }
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
    }
}

/// The handful of glyphs with no clean SF equivalent, drawn from the handoff
/// paths (24 view-box, scaled).
private struct DrawnGlyph: View {
    var icon: SuiteIcon
    var size: CGFloat

    var body: some View {
        let s = size / 24
        let lw = Theme.Icon.stroke * s * 1.25   // 24-box paths use ~2.0 here

        Path { p in
            switch icon {
            case .plus:
                p.move(to: CGPoint(x: 12 * s, y: 5 * s));  p.addLine(to: CGPoint(x: 12 * s, y: 19 * s))
                p.move(to: CGPoint(x: 5 * s, y: 12 * s));   p.addLine(to: CGPoint(x: 19 * s, y: 12 * s))
            case .check:
                p.move(to: CGPoint(x: 4 * s, y: 12.6 * s))
                p.addLine(to: CGPoint(x: 9.6 * s, y: 17 * s))
                p.addLine(to: CGPoint(x: 19 * s, y: 6.5 * s))
            case .xmark:
                p.move(to: CGPoint(x: 6 * s, y: 6 * s));   p.addLine(to: CGPoint(x: 18 * s, y: 18 * s))
                p.move(to: CGPoint(x: 18 * s, y: 6 * s));  p.addLine(to: CGPoint(x: 6 * s, y: 18 * s))
            default:
                break
            }
        }
        .stroke(style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
    }
}
