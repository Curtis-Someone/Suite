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

    // On-map country names. Tuned so names only appear once you've zoomed well
    // into a region — never on the world overview — and only on countries wide
    // enough on screen to hold the whole name. The nearest few to the view
    // centre win, so you get the country you're looking at plus its neighbours.
    private enum CountryLabel {
        /// Net zoom must clear this before any name is drawn at all.
        static let minZoom: CGFloat = 5.5
        static let size: CGFloat = 11
        static let weight: Font.Weight = .semibold
        /// Wide letter-spacing reads as cartographic rather than UI copy.
        static let tracking: CGFloat = 1.4
        /// Breathing room the name needs *inside* the country's on-screen width
        /// before it's allowed to show.
        static let fitInset: CGFloat = 18
        /// Cap on names shown at once, closest to the view centre first.
        static let maxCount = 5
    }

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
                // netZoom == zoom * pinch (t.a is size.width * that).
                let labelsOn = focus != nil || screenScale / size.width > CountryLabel.minZoom
                let viewMid = CGPoint(x: size.width / 2, y: size.height / 2)
                var labels: [(text: Text, at: CGPoint, onAmber: Bool, pull: CGFloat)] = []

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

                    // Name at the main-landmass centroid — only when zoomed
                    // deep in, only if the whole name fits inside the country
                    // on screen, and only while its centroid is on screen.
                    if labelsOn {
                        let at = c.center.applying(t)
                        let onScreen = at.x > 0 && at.x < size.width
                            && at.y > 0 && at.y < size.height
                        let text = Text(c.mapLabel.uppercased())
                            .font(.system(size: CountryLabel.size, weight: CountryLabel.weight))
                            .tracking(CountryLabel.tracking)
                        let nameWidth = ctx.resolve(text).measure(in: size).width
                        if onScreen, nameWidth + CountryLabel.fitInset <= c.unitSize * screenScale {
                            labels.append((text, at, isVisited,
                                           hypot(at.x - viewMid.x, at.y - viewMid.y)))
                        }
                    }
                }

                ctx.transform = .identity   // labels are positioned in screen space
                // A soft halo in the ground colour keeps a name legible where it
                // crosses a border or a busy coastline.
                var labelCtx = ctx
                labelCtx.addFilter(.shadow(color: ground.opacity(0.9), radius: 1.6, x: 0, y: 0))
                for label in labels.sorted(by: { $0.pull < $1.pull }).prefix(CountryLabel.maxCount) {
                    let ink = label.onAmber ? Color(hex: 0x1A130A) : labelInk
                    labelCtx.draw(label.text.foregroundStyle(ink), at: label.at)
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

    /// Pinch to zoom and one-finger drag to pan, recognised together so a
    /// two-finger gesture can do both at once.
    private var mapGesture: some Gesture {
        SimultaneousGesture(
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
                },
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
