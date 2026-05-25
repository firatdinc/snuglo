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
    ///
    /// ## Buffer semantiği
    /// Buffer kontrolü ham drag pozisyonuna (`pos`) göre yapılır — parça boyutundan bağımsız.
    /// Semantik: "drag noktası grid sınırından `buffer` pt'den uzaksa nil."
    static func snap(
        at pos: CGPoint,
        piece: Piece,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSize: (width: Int, height: Int),
        buffer: CGFloat = 15
    ) -> Coord? {
        guard gridFrame.width > 0 else { return nil }

        // IOS-16 FIX: buffer kontrolü ham pos koordinatına göre (parça offset'inden bağımsız).
        // Önceki: localX-tabanlı guard parça boyutuna göre etkili buffer'ı değiştiriyordu.
        guard pos.x >= gridFrame.minX - buffer,
              pos.y >= gridFrame.minY - buffer,
              pos.x <  gridFrame.maxX + buffer,
              pos.y <  gridFrame.maxY + buffer else { return nil }

        let pieceCols = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1)
        let pieceRows = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1)

        let localX = pos.x - pieceCols * cellSize / 2 - gridFrame.minX
        let localY = pos.y - pieceRows * cellSize / 2 - gridFrame.minY

        let col = Int(round(localX / cellSize))
        let row = Int(round(localY / cellSize))
        let clampedCol = max(0, min(col, gridSize.width  - Int(pieceCols)))
        let clampedRow = max(0, min(row, gridSize.height - Int(pieceRows)))

        return Coord(x: clampedCol, y: clampedRow)
    }
}
