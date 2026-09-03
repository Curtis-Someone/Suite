import SwiftUI

/// Flat vector world map, styled to the app's dark map surface. Pinch to zoom,
/// drag to pan. Visited countries fill solid amber. Vector, so it stays crisp
/// at any zoom.
struct WorldMapView: View {
    var visited: Set<String>
    /// Countries on the want-to-go list — drawn as a hollow amber tint.
    var wishlist: Set<String> = []
    /// The country whose sheet is open — gets a bright outline.
    var highlight: String? = nil
    /// When set, frames on this country and only fills it.
    var focus: String? = nil
    var interactive: Bool = true
    var onTapCountry: ((String) -> Void)? = nil

    @State private var zoom: CGFloat = 2.9
    @State private var pan: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    // Dark map palette — this surface is always dark (like the login hero).
    private let ground = Color(hex: 0x0E1012)
    private let land   = Color(hex: 0x2B2E33)
    private let landDim = Color(hex: 0x212327)
    private let border = Color(hex: 0x3B3E44)
    // Want-to-go: a solid muted gold, clearly dimmer than the visited amber.
    private let wishFill   = Color(hex: 0x7C6636)
    private let wishBorder = Color(hex: 0xA98A4E)

    var body: some View {
        GeometryReader { geo in
            let t = transform(in: geo.size)
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ground))
                let screenScale = t.a           // net unit → px scale
                var labels: [(String, CGPoint, Bool)] = []

                for c in WorldMap.countries where c.iso != "AQ" {
                    let p = c.path.applying(t)
                    let isVisited = visited.contains(c.iso)
                    let isWished = !isVisited && wishlist.contains(c.iso)
                    let fill: Color
                    if let focus {
                        fill = c.iso == focus ? Theme.Palette.accent : landDim
                    } else if isVisited {
                        fill = Theme.Palette.accent
                    } else if isWished {
                        fill = wishFill
                    } else {
                        fill = land
                    }
                    ctx.fill(p, with: .color(fill))
                    if isWished {
                        ctx.stroke(p, with: .color(wishBorder), lineWidth: 0.9)
                    } else if c.iso == highlight {
                        ctx.stroke(p, with: .color(.white.opacity(0.9)), lineWidth: 1.4)
                    } else {
                        ctx.stroke(p, with: .color(border), lineWidth: 0.5)
                    }

                    // Label at the main-landmass centroid, once it's big enough
                    // on screen and on screen at all.
                    if c.unitSize * screenScale > 58 {
                        let at = c.center.applying(t)
                        if at.x > -40, at.x < size.width + 40, at.y > 0, at.y < size.height {
                            labels.append((c.mapLabel, at, isVisited))
                        }
                    }
                }
                for (name, at, onAmber) in labels {
                    ctx.draw(
                        Text(name)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(onAmber ? Color(hex: 0x1A130A) : Color(hex: 0x8A857E)),
                        at: at)
                }
            }
            .contentShape(Rectangle())
            .gesture(interactive ? mapGesture : nil)
            .onTapGesture { loc in
                guard interactive, focus == nil, let onTapCountry else { return }
                let unit = loc.applying(t.inverted())
                if let hit = WorldMap.countries.first(where: { $0.contains(unit) }) {
                    onTapCountry(hit.iso)
                }
            }
        }
        .clipped()
    }

    // MARK: Gestures

    private var mapGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($pinch) { value, state, _ in state = value }
                .onEnded { zoom = min(24, max(1.6, zoom * $0)) },
            DragGesture()
                .updating($drag) { value, state, _ in state = value.translation }
                .onEnded { pan.width += $0.translation.width; pan.height += $0.translation.height }
        )
    }

    // MARK: Projection → view

    private func transform(in size: CGSize) -> CGAffineTransform {
        let base = size.width                        // unit square → view-wide
        let vc = CGPoint(x: size.width / 2, y: size.height / 2)

        if let focus, let c = WorldMap.country(for: focus) {
            let fz = min(18, max(1.6, 0.5 / c.unitSize))   // country fills ~half the view
            let s = base * fz
            return CGAffineTransform(scaleX: s, y: s)
                .concatenating(.init(translationX: vc.x - c.center.x * s,
                                     y: vc.y - c.center.y * s))
        }

        let z = zoom * pinch
        let s = base * z                                     // unit → px
        let livePan = CGSize(width: pan.width + drag.width, height: pan.height + drag.height)
        // Centre this unit point on the screen centre. y = 0.44 keeps the
        // populated band (≈60°N–50°S) filling the view without wasting height
        // on the empty Arctic / Antarctic.
        let target = CGPoint(x: 0.5, y: 0.43)
        return CGAffineTransform(scaleX: s, y: s)
            .concatenating(.init(translationX: vc.x - target.x * s + livePan.width,
                                 y: vc.y - target.y * s + livePan.height))
    }
}
