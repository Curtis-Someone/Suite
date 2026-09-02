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

    // Briefcase: handle + body + slats + feet.
    private func suitcaseShape(_ s: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3 * s)
                .fill(accent)
                .overlay(RoundedRectangle(cornerRadius: 3 * s).stroke(line, lineWidth: lineWidth * s))
                .frame(width: 16 * s, height: 12.6 * s)
                .position(x: 12 * s, y: 13.5 * s)

            RoundedRectangle(cornerRadius: 1.6 * s)
                .stroke(isActive ? Theme.Palette.accent : Theme.Palette.textTertiary, lineWidth: lineWidth * s)
                .frame(width: 5 * s, height: 4.6 * s)
                .position(x: 12 * s, y: 4.9 * s)

            Path { p in
                for x in [9.2, 12.0, 14.8] {
                    p.move(to: CGPoint(x: x * s, y: 10.4 * s))
                    p.addLine(to: CGPoint(x: x * s, y: 16.6 * s))
                }
            }
            .stroke(line, style: StrokeStyle(lineWidth: (isActive ? 1.4 : Theme.Icon.stroke) * s, lineCap: .round))

            ForEach([8.0, 16.0], id: \.self) { x in
                Circle()
                    .fill(isActive ? Theme.Palette.accent : .clear)
                    .overlay(Circle().stroke(isActive ? Theme.Palette.accent : Theme.Palette.textTertiary, lineWidth: lineWidth * s))
                    .frame(width: 2.4 * s, height: 2.4 * s)
                    .position(x: x * s, y: 21.2 * s)
            }
        }
    }

    // Passport / ID: cover + portrait circle + line.
    private func passportShape(_ s: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.4 * s)
                .fill(accent)
                .overlay(RoundedRectangle(cornerRadius: 2.4 * s).stroke(isActive ? Theme.Palette.accent : Theme.Palette.textTertiary, lineWidth: lineWidth * s))
                .frame(width: 15 * s, height: 18 * s)
                .position(x: 12 * s, y: 12 * s)

            Circle()
                .stroke(line, lineWidth: (isActive ? 1.6 : Theme.Icon.stroke) * s)
                .frame(width: 6.8 * s, height: 6.8 * s)
                .position(x: 12 * s, y: 10.6 * s)

            Path { p in
                p.move(to: CGPoint(x: 8.4 * s, y: 17.2 * s))
                p.addLine(to: CGPoint(x: 15.6 * s, y: 17.2 * s))
            }
            .stroke(line, style: StrokeStyle(lineWidth: (isActive ? 1.6 : Theme.Icon.stroke) * s, lineCap: .round))
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
