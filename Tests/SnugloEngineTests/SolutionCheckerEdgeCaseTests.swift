import XCTest
@testable import SnugloEngine

/// SolutionChecker için kenar durum testleri.
///
/// PlacementResult tam Equatable (tüm associated value'lar Equatable).
/// - .valid / .emptyGrid   → XCTAssertEqual (associated value yok)
/// - .overlap / .outOfBounds → XCTAssertEqual + kesin Coord (her iki yol da çalışır)
/// - .incompleteCoverage   → if-case (missing array sırası deterministik ama kırılgan olabilir)
final class SolutionCheckerEdgeCaseTests: XCTestCase {

    private let checker = SolutionChecker()

    // MARK: - Yardımcı: tek hücrelik "dot" parçası

    private func dot(id: String) -> Piece {
        Piece(id: id, cells: [Coord(x: 0, y: 0)])
    }

    // MARK: - Happy Path ──────────────────────────────────────────────────────

    /// 2×2 grid'i dört ayrı dot parçasıyla tam kapla → .valid beklenir.
    func testFullCoverage2x2WithFourDots() {
        let pieces = [dot(id: "a"), dot(id: "b"), dot(id: "c"), dot(id: "d")]
        let placements = [
            Placement(pieceId: "a", origin: Coord(x: 0, y: 0)),
            Placement(pieceId: "b", origin: Coord(x: 1, y: 0)),
            Placement(pieceId: "c", origin: Coord(x: 0, y: 1)),
            Placement(pieceId: "d", origin: Coord(x: 1, y: 1)),
        ]
        let level = Level(id: "tiny", width: 2, height: 2, pieces: pieces, solution: placements)
        XCTAssertEqual(checker.check(level: level, placements: placements), .valid)
    }

    /// 2×3 grid: L-parçası (4 hücre) + dikey 2-parçası → .valid beklenir.
    ///
    /// L  → (0,0),(1,0),(0,1),(0,2)
    /// R  → origin (1,1): absolute (1,1),(1,2)
    /// Birlikte tüm 6 hücreyi kaplar.
    func testFullCoverageWithLPiece() {
        let lPiece = Piece(id: "L", cells: [
            Coord(x: 0, y: 0), Coord(x: 1, y: 0),
            Coord(x: 0, y: 1),
            Coord(x: 0, y: 2),
        ])
        let rightCol = Piece(id: "R", cells: [
            Coord(x: 0, y: 0), Coord(x: 0, y: 1),
        ])
        let placements = [
            Placement(pieceId: "L", origin: Coord(x: 0, y: 0)),
            Placement(pieceId: "R", origin: Coord(x: 1, y: 1)),
        ]
        let level = Level(
            id: "L23", width: 2, height: 3,
            pieces: [lPiece, rightCol],
            solution: placements
        )
        XCTAssertEqual(checker.check(level: level, placements: placements), .valid)
    }

    // MARK: - Overlap ─────────────────────────────────────────────────────────

    /// Aynı pieceId'yi aynı origin'e iki kez yerleştirince overlap algılanmalı.
    ///
    /// ⚠️ level.pieces = [piece] (tek tanım). İki placement aynı pieceId'yi referans
    /// alır; birinci geçişte (0,0) işaretlenir, ikincide tekrar (0,0) → overlap.
    ///
    /// NOT: level.pieces = [piece, piece] YAPILMAZ — aynı id iki kez olunca
    /// `Dictionary(uniqueKeysWithValues:)` runtime crash atar.
    func testOverlapDetected() {
        let piece = Piece(id: "h2", cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
        // Tek parça tanımı; iki kez yerleştirme simülasyonu.
        let level = Level(id: "ovlp", width: 2, height: 2, pieces: [piece], solution: [])
        let placements = [
            Placement(pieceId: "h2", origin: Coord(x: 0, y: 0)),
            Placement(pieceId: "h2", origin: Coord(x: 0, y: 0)), // ikinci → (0,0) zaten dolu
        ]
        XCTAssertEqual(
            checker.check(level: level, placements: placements),
            .overlap(at: Coord(x: 0, y: 0))
        )
    }

    /// İki farklı parça çakışan hücreler oluşturduğunda overlap algılanmalı.
    ///
    /// "h2" origin (0,0) → (0,0),(1,0) kaplar.
    /// "dot" origin (1,0) → (1,0) tekrar → overlap(1,0).
    func testOverlapTwoDifferentPieces() {
        let h2  = Piece(id: "h2",  cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
        let dot = Piece(id: "dot", cells: [Coord(x: 0, y: 0)])
        let level = Level(id: "ovlp2", width: 2, height: 2, pieces: [h2, dot], solution: [])
        let placements = [
            Placement(pieceId: "h2",  origin: Coord(x: 0, y: 0)),
            Placement(pieceId: "dot", origin: Coord(x: 1, y: 0)),  // (1,0) → çakışır
        ]
        XCTAssertEqual(
            checker.check(level: level, placements: placements),
            .overlap(at: Coord(x: 1, y: 0))
        )
    }

    // MARK: - Out of Bounds ───────────────────────────────────────────────────

    /// Yatay 2-parça origin (1,0): absolute (1,0),(2,0) — x=2 ≥ width=2 → dışarı.
    func testOutOfBoundsRight() {
        let piece = Piece(id: "h2", cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
        let level = Level(id: "oob", width: 2, height: 2, pieces: [piece], solution: [])
        let placements = [Placement(pieceId: "h2", origin: Coord(x: 1, y: 0))]
        XCTAssertEqual(
            checker.check(level: level, placements: placements),
            .outOfBounds(at: Coord(x: 2, y: 0))
        )
    }

    /// Dikey 2-parça origin (0,1): absolute (0,1),(0,2) — y=2 ≥ height=2 → dışarı.
    func testOutOfBoundsBelow() {
        let piece = Piece(id: "v2", cells: [Coord(x: 0, y: 0), Coord(x: 0, y: 1)])
        let level = Level(id: "oob2", width: 2, height: 2, pieces: [piece], solution: [])
        let placements = [Placement(pieceId: "v2", origin: Coord(x: 0, y: 1))]
        XCTAssertEqual(
            checker.check(level: level, placements: placements),
            .outOfBounds(at: Coord(x: 0, y: 2))
        )
    }

    /// Negatif origin: parça x=-1 → outOfBounds.
    func testOutOfBoundsNegativeOrigin() {
        let piece = Piece(id: "v2", cells: [Coord(x: 0, y: 0), Coord(x: 0, y: 1)])
        let level = Level(id: "oob3", width: 2, height: 2, pieces: [piece], solution: [])
        let placements = [Placement(pieceId: "v2", origin: Coord(x: -1, y: 0))]
        XCTAssertEqual(
            checker.check(level: level, placements: placements),
            .outOfBounds(at: Coord(x: -1, y: 0))
        )
    }

    // MARK: - Partial / Incomplete Coverage ───────────────────────────────────

    /// 2×2 grid'in sadece üst satırı dolu (h2 origin 0,0) → incompleteCoverage.
    ///
    /// Missing: (0,1),(1,1) — SolutionChecker satır-önce üretir.
    func testPartialCoverage() {
        let piece = Piece(id: "h2", cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
        let level = Level(id: "partial", width: 2, height: 2, pieces: [piece], solution: [])
        let placements = [Placement(pieceId: "h2", origin: Coord(x: 0, y: 0))]
        XCTAssertEqual(
            checker.check(level: level, placements: placements),
            .incompleteCoverage(missing: [Coord(x: 0, y: 1), Coord(x: 1, y: 1)])
        )
    }

    /// Placements boşken (non-empty grid) tüm hücreler missing → incompleteCoverage.
    ///
    /// Fail-fast adım 2: placements.isEmpty → erken dönüş.
    func testNoPlacementsOnNonEmptyGridIsIncomplete() {
        let level = Level(id: "noplc", width: 3, height: 3, pieces: [], solution: [])
        let result = checker.check(level: level, placements: [])
        // 9 hücre: (0,0)..(2,2), satır-önce sıralı
        let allCoords = (0..<3).flatMap { y in (0..<3).map { x in Coord(x: x, y: y) } }
        XCTAssertEqual(result, .incompleteCoverage(missing: allCoords))
    }

    // MARK: - Empty Grid ──────────────────────────────────────────────────────

    /// width = 0 → emptyGrid.
    func testEmptyGridWidthZero() {
        let level = Level(id: "ew", width: 0, height: 3, pieces: [], solution: [])
        XCTAssertEqual(checker.check(level: level, placements: []), .emptyGrid)
    }

    /// height = 0 → emptyGrid.
    func testEmptyGridHeightZero() {
        let level = Level(id: "eh", width: 3, height: 0, pieces: [], solution: [])
        XCTAssertEqual(checker.check(level: level, placements: []), .emptyGrid)
    }

    /// Hem width hem height negatif → emptyGrid (guard width > 0, height > 0).
    func testEmptyGridBothNegative() {
        let level = Level(id: "en", width: -1, height: -1, pieces: [], solution: [])
        XCTAssertEqual(checker.check(level: level, placements: []), .emptyGrid)
    }
}
