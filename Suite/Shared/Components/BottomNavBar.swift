import SwiftUI

/// The three tabs, always in this order.
enum SuiteTab: CaseIterable {
    case map, suitcase, passport
}

/// Bottom navigation — exactly three icons, `map · suitcase · passport`.
/// Active icon is filled amber; inactive is a `textTertiary` stroke.
struct BottomNavBar: View {
    @Binding var selection: SuiteTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SuiteTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    TabGlyph(tab: tab, isActive: tab == selection)
                        .frame(width: Theme.Size.tabIcon, height: Theme.Size.tabIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 28)
        .frame(height: Theme.Size.navBar, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Palette.fillStrong)
                .frame(height: 1)
        }
    }
}

/// Tab icons, traced from the handoff (24 view-box).
private struct TabGlyph: View {
    var tab: SuiteTab
    var isActive: Bool

    private var accent: Color { isActive ? Theme.Palette.accent : .clear }
    private var line: Color { isActive ? Theme.Palette.onAccent : Theme.Palette.textTertiary }
    private var lineWidth: CGFloat { isActive ? 1.4 : Theme.Icon.stroke }

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 24
            ZStack {
                switch tab {
                case .map:      mapShape(s)
                case .suitcase: suitcaseShape(s)
                case .passport: passportShape(s)
                }
            }
        }
    }

    // Three overlapping panels.
    private func mapShape(_ s: CGFloat) -> some View {
        let panels = [
            [CGPoint(x: 2, y: 6), CGPoint(x: 9, y: 3), CGPoint(x: 9, y: 18), CGPoint(x: 2, y: 21)],
            [CGPoint(x: 9, y: 3), CGPoint(x: 15, y: 6), CGPoint(x: 15, y: 21), CGPoint(x: 9, y: 18)],
            [CGPoint(x: 15, y: 6), CGPoint(x: 22, y: 3), CGPoint(x: 22, y: 18), CGPoint(x: 15, y: 21)],
        ]
        return ForEach(0..<3, id: \.self) { i in
            polygon(panels[i], s)
                .fill(isActive ? Theme.Palette.accent : .clear)
                .overlay(
                    polygon(panels[i], s)
                        .stroke(isActive ? Theme.Palette.onAccent : Theme.Palette.textTertiary,
                                style: StrokeStyle(lineWidth: (isActive ? 1.2 : Theme.Icon.stroke) * s,
                                                   lineJoin: .round))
                )
        }
    }

    // Wheeled suitcase: telescoping handle + hard-shell body + ridge slats + side grab + spinner wheels.
    private func suitcaseShape(_ s: CGFloat) -> some View {
        ZStack {
            // Telescoping handle — inverted U rising above the shell.
            Path { p in
                p.move(to: CGPoint(x: 9.2 * s, y: 6.4 * s))
                p.addLine(to: CGPoint(x: 9.2 * s, y: 3.4 * s))
                p.addQuadCurve(to: CGPoint(x: 10.4 * s, y: 2.4 * s), control: CGPoint(x: 9.2 * s, y: 2.4 * s))
                p.addLine(to: CGPoint(x: 13.6 * s, y: 2.4 * s))
                p.addQuadCurve(to: CGPoint(x: 14.8 * s, y: 3.4 * s), control: CGPoint(x: 14.8 * s, y: 2.4 * s))
                p.addLine(to: CGPoint(x: 14.8 * s, y: 6.4 * s))
            }
            .stroke(line, style: StrokeStyle(lineWidth: lineWidth * s, lineCap: .round, lineJoin: .round))

            // Hard-shell body.
            RoundedRectangle(cornerRadius: 2.8 * s)
                .fill(accent)
                .overlay(RoundedRectangle(cornerRadius: 2.8 * s).stroke(line, lineWidth: lineWidth * s))
                .frame(width: 13.6 * s, height: 13.4 * s)
                .position(x: 12 * s, y: 13 * s)

            // Side grab handle — small nub on the right edge.
            RoundedRectangle(cornerRadius: 1 * s)
                .fill(accent)
                .overlay(RoundedRectangle(cornerRadius: 1 * s).stroke(line, lineWidth: lineWidth * s))
                .frame(width: 2 * s, height: 4.4 * s)
                .position(x: 19.4 * s, y: 12.6 * s)

            // Vertical ridge slats.
            Path { p in
                for x in [9.2, 12.0, 14.8] {
                    p.move(to: CGPoint(x: x * s, y: 8.8 * s))
                    p.addLine(to: CGPoint(x: x * s, y: 17.2 * s))
                }
            }
            .stroke(line, style: StrokeStyle(lineWidth: (isActive ? 1.3 : Theme.Icon.stroke) * s, lineCap: .round))

            // Spinner wheels.
            ForEach([9.4, 14.6], id: \.self) { x in
                Circle()
                    .stroke(line, lineWidth: lineWidth * s)
                    .frame(width: 2.2 * s, height: 2.2 * s)
                    .position(x: x * s, y: 20.9 * s)
            }
        }
    }

    // Passport: front cover peeled open above the spine, globe emblem, two ID lines.
    private func passportShape(_ s: CGFloat) -> some View {
        let thin = (isActive ? 1.6 : Theme.Icon.stroke) * s
        return ZStack {
            // Page block / inner cover.
            RoundedRectangle(cornerRadius: 2.2 * s)
                .fill(accent)
                .overlay(RoundedRectangle(cornerRadius: 2.2 * s).stroke(isActive ? Theme.Palette.accent : Theme.Palette.textTertiary, lineWidth: lineWidth * s))
                .frame(width: 13 * s, height: 15.2 * s)
                .position(x: 12 * s, y: 12.9 * s)

            // Opened front cover — shallow tent off the top edge.
            Path { p in
                p.move(to: CGPoint(x: 5.6 * s, y: 5.4 * s))
                p.addLine(to: CGPoint(x: 16.8 * s, y: 2.4 * s))
                p.addLine(to: CGPoint(x: 18.6 * s, y: 5.4 * s))
            }
            .stroke(line, style: StrokeStyle(lineWidth: lineWidth * s, lineCap: .round, lineJoin: .round))

            // Globe emblem — outline, meridian, equator.
            Circle()
                .stroke(line, lineWidth: thin)
                .frame(width: 7 * s, height: 7 * s)
                .position(x: 12 * s, y: 11 * s)
            Ellipse()
                .stroke(line, lineWidth: thin)
                .frame(width: 3 * s, height: 7 * s)
                .position(x: 12 * s, y: 11 * s)
            Path { p in
                p.move(to: CGPoint(x: 8.5 * s, y: 11 * s))
                p.addLine(to: CGPoint(x: 15.5 * s, y: 11 * s))
            }
            .stroke(line, style: StrokeStyle(lineWidth: thin, lineCap: .round))

            // Two ID lines below the emblem.
            Path { p in
                p.move(to: CGPoint(x: 8.8 * s, y: 16.2 * s))
                p.addLine(to: CGPoint(x: 15.2 * s, y: 16.2 * s))
                p.move(to: CGPoint(x: 10.2 * s, y: 18.2 * s))
                p.addLine(to: CGPoint(x: 13.8 * s, y: 18.2 * s))
            }
            .stroke(line, style: StrokeStyle(lineWidth: thin, lineCap: .round))
        }
    }

    private func polygon(_ pts: [CGPoint], _ s: CGFloat) -> Path {
        Path { p in
            guard let first = pts.first else { return }
            p.move(to: CGPoint(x: first.x * s, y: first.y * s))
            for pt in pts.dropFirst() { p.addLine(to: CGPoint(x: pt.x * s, y: pt.y * s)) }
            p.closeSubpath()
        }
    }
}
