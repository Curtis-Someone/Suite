import SwiftUI

/// Flat vector world map. Pinch to zoom, drag to pan. Visited countries fill
/// solid amber. Vector, so it stays crisp at any zoom. Follows the app theme:
/// a night-map surface in dark, the handoff's pale paper map in light. Pass
/// `scheme: .dark` to pin it dark regardless of the system setting — the
/// Share-card and paywall heroes do this, as they sit under a heavy dark
/// gradient with white text in both appearances.
struct WorldMapView: View {
    var visited: Set<String>
    /// Countries on the want-to-go list — drawn as a hollow amber tint.
    var wishlist: Set<String> = []
    /// The country whose sheet is open — gets a bright outline.
    var highlight: String? = nil
    /// When set, frames on this country and only fills it.
    var focus: String? = nil
    var interactive: Bool = true
    /// Pin the map palette to one appearance, ignoring the system setting.
    var scheme: ColorScheme? = nil
    var onTapCountry: ((String) -> Void)? = nil

    @Environment(\.colorScheme) private var systemScheme
    @State private var zoom: CGFloat = 2.9
    @State private var pan: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    private var isDark: Bool { (scheme ?? systemScheme) == .dark }

    // Map palette. Dark = the app's hand-tuned night-map surface. Light = the
    // Claude Design handoff's Map-tab palette (MAPCFG): pale taupe land on a
    // white ocean, hairline white country borders.
    private var ground:  Color { isDark ? Color(hex: 0x0E1012) : Color(hex: 0xFFFFFF) }
    private var land:    Color { isDark ? Color(hex: 0x2B2E33) : Color(hex: 0xDEDAD2) }
    private var landDim: Color { isDark ? Color(hex: 0x212327) : Color(hex: 0xEBE8E1) }
    private var border:  Color { isDark ? Color(hex: 0x3B3E44) : Color(hex: 0xFFFFFF) }
    // Want-to-go: a solid muted gold, clearly dimmer than the visited amber.
    private var wishFill:   Color { isDark ? Color(hex: 0x7C6636) : Color(hex: 0xE7CE9E) }
    private var wishBorder: Color { isDark ? Color(hex: 0xA98A4E) : Color(hex: 0xC9A057) }
    // Outline on the country whose sheet is open.
    private var highlightStroke: Color { isDark ? Color.white.opacity(0.9) : Color(hex: 0x1A1A1A).opacity(0.65) }
    // Centroid label on a non-visited country (visited ones use dark-on-amber).
    private var labelInk: Color { isDark ? Color(hex: 0x8A857E) : Color(hex: 0x77736C) }

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
                        ctx.stroke(c.path, with: .color(highlightStroke), lineWidth: 1.4 * hair)
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
                            .foregroundStyle(onAmber ? Color(hex: 0x1A130A) : labelInk),
                        at: at)
                }
            }
            .contentShape(Rectangle())
            .gesture(interactive ? pinchGesture : nil)
            // The map owns finger drags at any zoom so you can pan freely;
            // switch tabs with the bottom pill. highPriority so the drag wins
            // over the paged TabView's swipe.
            .highPriorityGesture(interactive ? panGesture : nil)
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
        DragGesture(minimumDistance: 3)
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
