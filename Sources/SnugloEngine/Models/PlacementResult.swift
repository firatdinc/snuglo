import Foundation

/// `SolutionChecker.check(level:placements:)` dönüş değeri.
///
/// - `valid`: Tüm hücreler kaplı, overlap yok, sınır ihlali yok.
/// - `overlap(at:)`: İki parça aynı hücreyi kaplamaya çalışıyor.
/// - `outOfBounds(at:)`: Bir parça hücresi grid sınırları dışında.
/// - `incompleteCoverage(missing:)`: Grid'de boş kalan hücreler var.
/// - `emptyGrid`: Level width veya height sıfır/negatif.
/// - `unknownPiece(id:)`: `placements` içindeki `pieceId`, level'da tanımlı değil.
public enum PlacementResult: Equatable, Sendable {
    case valid
    case overlap(at: Coord)
    case outOfBounds(at: Coord)
    case incompleteCoverage(missing: [Coord])
    case emptyGrid
    case unknownPiece(id: String)
}
