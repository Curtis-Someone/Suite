import SwiftUI

/// A country outline from `world.min.json` (Natural Earth 50m), projected with
/// Web Mercator into unit space (x, y roughly 0…1 — the projection every slippy
/// map uses, so proportions look right). Scale to the view at draw time.
struct WorldCountry: Identifiable {
    let iso: String
    let name: String
    let path: Path
    /// Unit-space bounding box of the whole outline, for off-screen culling.
    let bounds: CGRect
    /// Unit-space centre + rough size of the largest landmass, for framing.
    let center: CGPoint
    let unitSize: CGFloat

    var id: String { iso }
    func contains(_ p: CGPoint) -> Bool { path.contains(p) }

    /// A short name for the on-map label.
    var mapLabel: String {
        switch iso {
        case "US": return "United States"
        case "GB": return "United Kingdom"
        case "AE": return "UAE"
        case "CD": return "DR Congo"
        case "CF": return "Central African Rep."
        case "CZ": return "Czechia"
        default:
            if name.count > 18, let comma = name.firstIndex(of: ",") {
                return String(name[..<comma])
            }
            return name
        }
    }
}

enum WorldMap {
    static let countries: [WorldCountry] = load()

    static func mercatorY(_ lat: Double) -> Double {
        let l = max(-85, min(85, lat)) * .pi / 180
        return 0.5 - log(tan(.pi / 4 + l / 2)) / (2 * .pi)
    }
    static func mercatorX(_ lon: Double) -> Double { (lon + 180) / 360 }

    private struct Raw: Decodable {
        let iso: String
        let name: String
        let polys: [[[[Double]]]]   // [polygon][ring][point][lon,lat]
    }

    private static func load() -> [WorldCountry] {
        guard let url = Bundle.main.url(forResource: "world.min", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([Raw].self, from: data)
        else { return [] }

        return raw.compactMap { c in
            var path = Path()
            var biggest: (pts: [CGPoint], count: Int) = ([], 0)
            for polygon in c.polys {
                for (ri, ring) in polygon.enumerated() where ring.count > 2 {
                    var pts: [CGPoint] = []
                    pts.reserveCapacity(ring.count)
                    for pt in ring {
                        pts.append(CGPoint(x: mercatorX(pt[0]), y: mercatorY(pt[1])))
                    }
                    for (i, p) in pts.enumerated() {
                        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    path.closeSubpath()
                    if ri == 0, ring.count > biggest.count { biggest = (pts, ring.count) }
                }
            }
            guard !biggest.pts.isEmpty else { return nil }
            let xs = biggest.pts.map(\.x), ys = biggest.pts.map(\.y)
            let center = CGPoint(x: (xs.min()! + xs.max()!) / 2, y: (ys.min()! + ys.max()!) / 2)
            let size = max(xs.max()! - xs.min()!, ys.max()! - ys.min()!)
            return WorldCountry(iso: c.iso, name: c.name, path: path,
                                bounds: path.boundingRect,
                                center: center, unitSize: max(0.01, size))
        }
    }

    static func country(for iso: String) -> WorldCountry? {
        countries.first { $0.iso == iso.uppercased() }
    }
}
