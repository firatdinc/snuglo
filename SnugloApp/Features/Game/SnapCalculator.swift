import CoreGraphics
import SnugloEngine

/// Drag sırasında bir parçanın hangi grid hücresine snap edeceğini hesaplar.
/// Pure hesaplama — SwiftUI state'e bağımlılığı yok, doğrudan unit-test edilebilir.
enum SnapCalculator {

    /// Drag pozisyonundan hedef grid koordinatını hesaplar.
    ///
    /// - Parameters:
    ///   - pos:       Drag lokasyonu (gameLayout coordinate space).
    ///   - piece:     Sürüklenen parça (cells dizisi lokal offset'leri tutar).
    ///   - gridFrame: Grid view'ın ekran içindeki CGRect'i.
    ///   - cellSize:  Tek bir hücrenin piksel boyutu (genişlik == yükseklik).
    ///   - gridSize:  Griddeki sütun ve satır sayısı (width, height).
    ///   - buffer:    Grid sınırı dışında kabul edilen tolerans (default 15 pt).
    /// - Returns:     Snap hedefi `Coord`, ya da parça buffer dışındaysa `nil`.
    static func snap(
        at pos: CGPoint,
        piece: Piece,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSize: (width: Int, height: Int),
        buffer: CGFloat = 15
    ) -> Coord? {
        guard gridFrame.width > 0 else { return nil }

        let pieceCols = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1)
        let pieceRows = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1)

        let localX = pos.x - pieceCols * cellSize / 2 - gridFrame.minX
        let localY = pos.y - pieceRows * cellSize / 2 - gridFrame.minY

        guard localX >= -buffer, localY >= -buffer,
              localX < gridFrame.width  + buffer,
              localY < gridFrame.height + buffer else { return nil }

        let col = Int(round(localX / cellSize))
        let row = Int(round(localY / cellSize))
        let clampedCol = max(0, min(col, gridSize.width  - Int(pieceCols)))
        let clampedRow = max(0, min(row, gridSize.height - Int(pieceRows)))

        return Coord(x: clampedCol, y: clampedRow)
    }
}
