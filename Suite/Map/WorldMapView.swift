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
            Canvas(opaque: true) { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ground))
                let screenScale = t.a           // net unit → px scale
                // Strokes are authored in screen pt; undo the CTM scale so they
                // stay hairline-thin at every zoom level.
                let hair = 1 / screenScale
                let viewRect = CGRect(origin: .zero, size: size).insetBy(dx: -2, dy: -2)
                var labels: [(String, CGPoint, Bool)] = []

                // Draw in unit space: set the transform on the context once
                // rather than rebuilding every country's Path each frame.
                ctx.transform = t

                for c in WorldMap.countries where c.iso != "AQ" {
                    guard c.bounds.applying(t).intersects(viewRect) else { continue }
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
                    ctx.fill(c.path, with: .color(fill))
                    if isWished {
                        ctx.stroke(c.path, with: .color(wishBorder), lineWidth: 0.9 * hair)
                    } else if c.iso == highlight {
                        ctx.stroke(c.path, with: .color(.white.opacity(0.9)), lineWidth: 1.4 * hair)
                    } else {
                        ctx.stroke(c.path, with: .color(border), lineWidth: 0.5 * hair)
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

                ctx.transform = .identity   // labels are positioned in screen space
                for (name, at, onAmber) in labels {
                    ctx.draw(
                        Text(name)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(onAmber ? Color(hex: 0x1A130A) : Color(hex: 0x8A857E)),
                        at: at)
                }
            }
            .contentShape(Rectangle())
            .gesture(interactive ? pinchGesture : nil)
            // One-finger pan only once the user has zoomed in — otherwise a
            // horizontal drag belongs to the tab-swipe, not the map.
            .gesture((interactive && zoom * pinch > 3.4) ? panGesture : nil)
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

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($pinch) { value, state, _ in state = value }
            .onEnded { value in
                let newZoom = min(24, max(1.6, zoom * value))
                // Bake the same factor into the pan so the point under the
                // screen centre stays put when the live gesture ends.
                let applied = newZoom / zoom
                pan.width *= applied
                pan.height *= applied
                zoom = newZoom
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded { pan.width += $0.translation.width; pan.height += $0.translation.height }
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
        // While a pinch is live, scale the accumulated pan by the same factor
        // so the map zooms about the screen centre instead of sliding under
        // the fingers. (pinch == 1 when no pinch is in progress.)
        let livePan = CGSize(width: pan.width * pinch + drag.width,
                             height: pan.height * pinch + drag.height)
        // Centre this unit point on the screen centre. y = 0.44 keeps the
        // populated band (≈60°N–50°S) filling the view without wasting height
        // on the empty Arctic / Antarctic.
        let target = CGPoint(x: 0.5, y: 0.43)
        return CGAffineTransform(scaleX: s, y: s)
            .concatenating(.init(translationX: vc.x - target.x * s + livePan.width,
                                 y: vc.y - target.y * s + livePan.height))
    }
}
