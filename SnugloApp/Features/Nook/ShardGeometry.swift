import SwiftUI

// MARK: — ShardGeometry
// The scene PNGs are transparent, island-shaped art — not rectangles — so a grid
// split looks wrong. Instead the picture is broken like glass: 6 irregular shards
// radiating from an off-centre impact point. The pattern is FIXED (deterministic,
// computed once) so a shard always maps to the same region across renders and the
// dragged piece lines up with its slot. All coordinates are normalized (0…1) and
// scaled to the canvas at draw time by `ShardShape`.

enum ShardGeometry {

    static let count = 6
    private static let center = CGPoint(x: 0.52, y: 0.46)
    /// Irregular ray angles (degrees, ascending) → glass-shatter wedges.
    private static let raysDeg: [Double] = [14, 66, 118, 176, 232, 304]

    /// The 6 shard polygons (normalized), tiling the whole canvas rect.
    static let shards: [[CGPoint]] = buildShards()

    private static func buildShards() -> [[CGPoint]] {
        let corners = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
                       CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]

        func angle(of p: CGPoint) -> Double {
            var a = atan2(Double(p.y - center.y), Double(p.x - center.x)) * 180 / .pi
            if a < 0 { a += 360 }
            return a
        }

        func perimeter(_ deg: Double) -> CGPoint {
            let r = deg * .pi / 180
            let dx = cos(r), dy = sin(r)
            var t = Double.greatestFiniteMagnitude
            if dx > 1e-9 { t = min(t, (1 - Double(center.x)) / dx) }
            if dx < -1e-9 { t = min(t, (0 - Double(center.x)) / dx) }
            if dy > 1e-9 { t = min(t, (1 - Double(center.y)) / dy) }
            if dy < -1e-9 { t = min(t, (0 - Double(center.y)) / dy) }
            let x = Double(center.x) + t * dx
            let y = Double(center.y) + t * dy
            return CGPoint(x: min(1, max(0, x)), y: min(1, max(0, y)))
        }

        // Stable pseudo-random in 0…1 (GLSL-style hash) → deterministic jaggedness.
        func hash(_ a: Double, _ b: Double) -> Double {
            let v = sin(a * 12.9898 + b * 78.233) * 43758.5453
            return v - floor(v)
        }

        // A crack from the centre out to `p`, zig-zagged perpendicular to its
        // direction so it looks like shattered glass (girintili-çıkıntılı). Tapered
        // to 0 at both ends so every crack still meets exactly at the centre and at
        // its perimeter point — the SAME polyline is shared by the two neighbouring
        // shards (used forward by one, reversed by the other) so there are no gaps.
        func jaggedRay(index i: Int, to p: CGPoint) -> [CGPoint] {
            let segments = 7
            let dx = Double(p.x - center.x), dy = Double(p.y - center.y)
            let len = (dx * dx + dy * dy).squareRoot()
            guard len > 1e-6 else { return [center, p] }
            let nx = -dy / len, ny = dx / len      // unit perpendicular
            let amp = 0.07
            var pts: [CGPoint] = [center]
            for k in 1..<segments {
                let t = Double(k) / Double(segments)
                let taper = sin(.pi * t)            // 0 at both ends, max mid
                let sign: Double = (k % 2 == 0) ? 1 : -1   // alternate in/out
                let mag = amp * taper * sign * (0.45 + 0.55 * hash(Double(i), Double(k)))
                let x = Double(center.x) + t * dx + mag * nx
                let y = Double(center.y) + t * dy + mag * ny
                pts.append(CGPoint(x: min(1, max(0, x)), y: min(1, max(0, y))))
            }
            pts.append(p)
            return pts
        }

        let perims = raysDeg.map { perimeter($0) }
        let rays = (0..<raysDeg.count).map { jaggedRay(index: $0, to: perims[$0]) }
        let cornerAngles = corners.map { angle(of: $0) }

        var polys: [[CGPoint]] = []
        for i in 0..<raysDeg.count {
            let a0 = raysDeg[i]
            let next = (i + 1) % raysDeg.count
            let a1 = (i + 1 < raysDeg.count) ? raysDeg[i + 1] : raysDeg[0] + 360
            // centre → (jagged) → perim_i → rectangle corners → perim_{i+1} → (jagged) → centre
            var poly = rays[i]
            var insiders: [(Double, CGPoint)] = []
            for (idx, c) in corners.enumerated() {
                var ca = cornerAngles[idx]
                if ca < a0 { ca += 360 }
                if ca > a0 && ca < a1 { insiders.append((ca, c)) }
            }
            insiders.sort { $0.0 < $1.0 }
            poly.append(contentsOf: insiders.map { $0.1 })
            poly.append(contentsOf: rays[next].reversed())
            polys.append(poly)
        }
        return polys
    }

    static func bbox(_ poly: [CGPoint]) -> CGRect {
        let xs = poly.map { $0.x }, ys = poly.map { $0.y }
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
        return CGRect(x: minX, y: minY,
                      width: max(0.0001, maxX - minX),
                      height: max(0.0001, maxY - minY))
    }

    static func centroid(_ poly: [CGPoint]) -> CGPoint {
        guard !poly.isEmpty else { return CGPoint(x: 0.5, y: 0.5) }
        let sx = poly.reduce(0) { $0 + $1.x }
        let sy = poly.reduce(0) { $0 + $1.y }
        return CGPoint(x: sx / CGFloat(poly.count), y: sy / CGFloat(poly.count))
    }

    /// Point-in-polygon (ray casting); `pt` and `poly` both normalized.
    static func contains(_ poly: [CGPoint], _ pt: CGPoint) -> Bool {
        var inside = false
        var j = poly.count - 1
        for i in 0..<poly.count {
            let a = poly[i], b = poly[j]
            if (a.y > pt.y) != (b.y > pt.y),
               pt.x < (b.x - a.x) * (pt.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}

// MARK: — ShardShape (draws a normalized polygon scaled into its rect)

struct ShardShape: Shape {
    let points: [CGPoint]   // normalized 0…1
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let f = points.first else { return p }
        func map(_ q: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + q.x * rect.width, y: rect.minY + q.y * rect.height)
        }
        p.move(to: map(f))
        for q in points.dropFirst() { p.addLine(to: map(q)) }
        p.closeSubpath()
        return p
    }
}
