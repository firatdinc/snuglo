import XCTest
import CoreGraphics
import SnugloEngine
@testable import SnugloApp

/// SnapCalculator unit testleri — 3 temel senaryo:
///   1. Ortada snap — grid ortasına sürükleme doğru Coord döner
///   2. Sınırda clamp — grid sınırı dışı pozisyon, geçerli max koordinata sıkıştırılır
///   3. Buffer dışında nil — buffer toleransını aşan pozisyon nil döner
final class SnapCalculatorTests: XCTestCase {

    // MARK: - Helpers

    /// 5×5 grid, 50pt cellSize → gridFrame = (0,0,250,250)
    private let gridFrame = CGRect(x: 0, y: 0, width: 250, height: 250)
    private let cellSize: CGFloat = 50
    private let gridSize = (width: 5, height: 5)

    /// 1×1 tek hücreli parça
    private func singleCell() -> Piece {
        Piece(id: "s", cells: [Coord(x: 0, y: 0)])
    }

    /// 2×1 yatay parça (2 sütun, 1 satır)
    private func twoWide() -> Piece {
        Piece(id: "w", cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
    }

    // MARK: - 1. Ortada snap

    /// Grid tam ortasına (125,125) sürüklenen 1×1 parça → Coord(2,2)
    func test_snap_centerOfGrid_returnsCenterCoord() {
        // Piece merkezi grid ortasında: local (125,125) → col=2, row=2
        let pos = CGPoint(
            x: gridFrame.minX + 2.5 * cellSize,  // merkezin drag lokasyonu
            y: gridFrame.minY + 2.5 * cellSize
        )
        let result = SnapCalculator.snap(
            at: pos,
            piece: singleCell(),
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSize: gridSize
        )
        XCTAssertEqual(result, Coord(x: 2, y: 2))
    }

    // MARK: - 2. Sınırda clamp

    /// Parça grid sınırını aşan (sağa) bir pozisyona sürüklendi → max geçerli sütuna clamp
    func test_snap_beyondRightEdge_clampsToMaxCol() {
        // 2×1 parça için maxCol = gridSize.width - pieceCols = 5 - 2 = 3
        // Drag pozisyonu: gridFrame.maxX + buffer - 1 (hâlâ geçerli buffer içinde)
        let pos = CGPoint(
            x: gridFrame.maxX + 10,  // buffer=15 içinde
            y: gridFrame.minY + cellSize / 2  // row 0
        )
        let result = SnapCalculator.snap(
            at: pos,
            piece: twoWide(),
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSize: gridSize
        )
        XCTAssertNotNil(result, "Buffer içindeki pozisyon nil döndürmemeli")
        XCTAssertEqual(result?.x, 3, "Sınır aşımı max geçerli sütuna (3) clamp edilmeli")
    }

    // MARK: - 3. Buffer dışında nil

    /// Parça grid'den buffer'ı aşacak kadar uzakta → nil
    func test_snap_outsideBuffer_returnsNil() {
        // gridFrame.maxX = 250, buffer = 15 → 250 + 16 = 266 buffer dışı
        let pos = CGPoint(
            x: gridFrame.maxX + 16,
            y: gridFrame.minY + cellSize / 2
        )
        let result = SnapCalculator.snap(
            at: pos,
            piece: singleCell(),
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSize: gridSize
        )
        XCTAssertNil(result, "Buffer dışındaki pozisyon nil dönmeli")
    }

    // MARK: - 4. Sıfır genişlikli frame → nil (guard koşulu)

    func test_snap_zeroWidthFrame_returnsNil() {
        let result = SnapCalculator.snap(
            at: CGPoint(x: 100, y: 100),
            piece: singleCell(),
            gridFrame: .zero,
            cellSize: cellSize,
            gridSize: gridSize
        )
        XCTAssertNil(result, "gridFrame.width == 0 olduğunda nil dönmeli")
    }
}
