import Foundation

/// Grid'de yapılan yerleşimleri doğrular.
///
/// Fail-fast sırası:
///   1. emptyGrid      → width/height ≤ 0
///   2. boş placements → incompleteCoverage(tüm grid)
///   3. unknownPiece   → pieceId level'da tanımlı değil
///   4. outOfBounds    → herhangi absolute koord grid dışı
///   5. overlap        → hücre zaten dolu
///   6. incompleteCoverage → bazı hücreler boş kaldı
///   7. valid          → tüm hücreler doldu
public struct SolutionChecker: Sendable {

    public init() {}

    /// - Parameters:
    ///   - level: Doğrulanacak seviye (grid boyutu + parça tanımları).
    ///   - placements: Kullanıcının veya hint motorunun yaptığı yerleşimler.
    /// - Returns: `PlacementResult` — ilk hata anında erken dönüş yapılır.
    public func check(level: Level, placements: [Placement]) -> PlacementResult {

        // ── 1. Boş/geçersiz grid ─────────────────────────────────────────────
        guard level.width > 0, level.height > 0 else {
            return .emptyGrid
        }

        // ── 2. Hiç yerleşim yapılmamış ───────────────────────────────────────
        if placements.isEmpty {
            return .incompleteCoverage(missing: allCoords(width: level.width, height: level.height))
        }

        // ── Parça arama sözlüğü ──────────────────────────────────────────────
        let pieceMap: [String: Piece] = Dictionary(
            uniqueKeysWithValues: level.pieces.map { ($0.id, $0) }
        )

        // ── 3 & 4. Bounds + overlap ──────────────────────────────────────────
        // grid[y][x]: hücre dolu mu?
        var grid = Array(
            repeating: Array(repeating: false, count: level.width),
            count: level.height
        )

        for placement in placements {
            // Bilinmeyen pieceId → erken hata dön
            guard let piece = pieceMap[placement.pieceId] else {
                return .unknownPiece(id: placement.pieceId)
            }

            for cell in piece.cells {
                let ax = cell.x + placement.origin.x
                let ay = cell.y + placement.origin.y

                // Sınır dışı kontrolü
                guard ax >= 0, ax < level.width, ay >= 0, ay < level.height else {
                    return .outOfBounds(at: Coord(x: ax, y: ay))
                }

                // Üst üste binme kontrolü
                if grid[ay][ax] {
                    return .overlap(at: Coord(x: ax, y: ay))
                }

                grid[ay][ax] = true
            }
        }

        // ── 5. Kapsama kontrolü ──────────────────────────────────────────────
        var missing: [Coord] = []
        for y in 0..<level.height {
            for x in 0..<level.width where !grid[y][x] {
                missing.append(Coord(x: x, y: y))
            }
        }

        // ── 6. Sonuç ─────────────────────────────────────────────────────────
        return missing.isEmpty ? .valid : .incompleteCoverage(missing: missing)
    }

    // MARK: - Yardımcı

    /// Verilen boyuttaki grid'in tüm koordinatlarını üretir (satır-önce sıralı).
    private func allCoords(width: Int, height: Int) -> [Coord] {
        var coords: [Coord] = []
        coords.reserveCapacity(width * height)
        for y in 0..<height {
            for x in 0..<width {
                coords.append(Coord(x: x, y: y))
            }
        }
        return coords
    }
}
