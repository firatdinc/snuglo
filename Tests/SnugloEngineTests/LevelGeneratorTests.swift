import XCTest
@testable import SnugloEngine

final class LevelGeneratorTests: XCTestCase {

    private let gen = LevelGenerator()
    private let checker = SolutionChecker()

    // MARK: - Determinizm

    /// Aynı argümanlar → özdeş Level.
    func testGenerateDeterministic() {
        let a = gen.generate(packId: "cozy-beginnings", levelIndex: 1, gridSize: 5)
        let b = gen.generate(packId: "cozy-beginnings", levelIndex: 1, gridSize: 5)
        XCTAssertEqual(a, b, "Aynı input → özdeş Level")
    }

    /// Farklı levelIndex → farklı Level.
    func testDifferentIndexProducesDifferentLevel() {
        let a = gen.generate(packId: "cozy-beginnings", levelIndex: 1, gridSize: 5)
        let b = gen.generate(packId: "cozy-beginnings", levelIndex: 2, gridSize: 5)
        XCTAssertNotEqual(a, b)
    }

    /// Farklı packId → farklı Level.
    func testDifferentPackIdProducesDifferentLevel() {
        let a = gen.generate(packId: "pack-alpha", levelIndex: 1, gridSize: 5)
        let b = gen.generate(packId: "pack-beta", levelIndex: 1, gridSize: 5)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Geçerli Çözüm

    /// Her üretilen level'ın solution'ı SolutionChecker'dan .valid çıkmalı.
    func testGenerateProducesValidSolution() {
        for levelIndex in [1, 10, 20, 21, 40, 60] {
            let level  = gen.generate(packId: "test-pack", levelIndex: levelIndex, gridSize: 5)
            let result = checker.check(level: level, placements: level.solution)
            XCTAssertEqual(result, .valid,
                           "levelIndex=\(levelIndex) solution must be .valid, got \(result)")
        }
    }

    /// 6×6, 7×7, 8×8 için de solution geçerli olmalı.
    func testGenerateValidSolutionAllGridSizes() {
        for size in [5, 6, 7, 8] {
            for idx in [1, 30, 60] {
                let level  = gen.generate(packId: "multi-size", levelIndex: idx, gridSize: size)
                let result = checker.check(level: level, placements: level.solution)
                XCTAssertEqual(result, .valid,
                               "gridSize=\(size) levelIndex=\(idx) solution must be .valid")
            }
        }
    }

    // MARK: - generateAll

    /// generateAll → 60 distinct level.
    func testGenerateAll60() {
        let levels = gen.generateAll(packId: "cozy-beginnings", gridSize: 5, count: 60)
        XCTAssertEqual(levels.count, 60)

        // ID'ler eşsiz olmalı
        let ids = Set(levels.map(\.id))
        XCTAssertEqual(ids.count, 60, "Her level'ın benzersiz id'si olmalı")
    }

    /// generateAll determinizm: aynı çağrı → aynı liste.
    func testGenerateAllDeterministic() {
        let a = gen.generateAll(packId: "omega", gridSize: 6, count: 10)
        let b = gen.generateAll(packId: "omega", gridSize: 6, count: 10)
        XCTAssertEqual(a, b)
    }

    /// count=0 → boş dizi, crash yok.
    func testGenerateAllCountZero() {
        let levels = gen.generateAll(packId: "x", gridSize: 5, count: 0)
        XCTAssertTrue(levels.isEmpty)
    }

    // MARK: - Grid Boyutu

    /// 5×5 pack için Level.width == 5 ve Level.height == 5.
    func testGridSizeRespected5x5() {
        let level = gen.generate(packId: "cozy-beginnings", levelIndex: 1, gridSize: 5)
        XCTAssertEqual(level.width, 5)
        XCTAssertEqual(level.height, 5)
    }

    /// 8×8 pack için Level.width == 8 ve Level.height == 8.
    func testGridSizeRespected8x8() {
        let level = gen.generate(packId: "big-pack", levelIndex: 1, gridSize: 8)
        XCTAssertEqual(level.width, 8)
        XCTAssertEqual(level.height, 8)
    }

    // MARK: - Difficulty Curve / Piece Count

    /// 5×5, levelIndex 1-20 → 4 piece.
    func testPieceCountInRange_5x5_easy() {
        let level = gen.generate(packId: "cozy-beginnings", levelIndex: 5, gridSize: 5)
        XCTAssertEqual(level.pieces.count, 4,
                       "5×5 levelIndex ≤20 → 4 piece bekleniyor")
    }

    /// 5×5, levelIndex 21-60 → 5 piece.
    func testPieceCountInRange_5x5_hard() {
        let level = gen.generate(packId: "cozy-beginnings", levelIndex: 25, gridSize: 5)
        XCTAssertEqual(level.pieces.count, 5,
                       "5×5 levelIndex 21-60 → 5 piece bekleniyor")
    }

    /// 8×8, levelIndex 41-60 → 12 piece.
    func testPieceCountInRange_8x8_hardest() {
        let level = gen.generate(packId: "hard-pack", levelIndex: 50, gridSize: 8)
        XCTAssertEqual(level.pieces.count, 12,
                       "8×8 levelIndex 41-60 → 12 piece bekleniyor")
    }

    // MARK: - Yapısal Bütünlük

    /// Her piece en az 1 hücre içermeli.
    func testAllPiecesNonEmpty() {
        let level = gen.generate(packId: "integrity", levelIndex: 1, gridSize: 7)
        for piece in level.pieces {
            XCTAssertFalse(piece.cells.isEmpty, "Piece \(piece.id) boş olamaz")
        }
    }

    /// Piece hücrelerinin toplamı = width × height.
    func testTotalCellsCoverGrid() {
        for size in [5, 6, 7, 8] {
            let level = gen.generate(packId: "coverage", levelIndex: 1, gridSize: size)
            let totalCells = level.pieces.reduce(0) { $0 + $1.cells.count }
            XCTAssertEqual(totalCells, size * size,
                           "\(size)×\(size) grid için toplam cell sayısı \(size*size) olmalı")
        }
    }

    /// Level ID format: "\(packId)-\(levelIndex)".
    func testLevelIdFormat() {
        let level = gen.generate(packId: "mypack", levelIndex: 7, gridSize: 5)
        XCTAssertEqual(level.id, "mypack-7")
    }

    /// Piece ID'leri eşsiz olmalı.
    func testPieceIdsUnique() {
        let level = gen.generate(packId: "uniqueness", levelIndex: 1, gridSize: 6)
        let ids = level.pieces.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Piece ID'leri benzersiz olmalı")
    }

    /// Solution'daki her pieceId Level.pieces'te var olmalı.
    func testSolutionPieceIdsMatchPieces() {
        let level = gen.generate(packId: "consistency", levelIndex: 3, gridSize: 5)
        let pieceIdSet = Set(level.pieces.map(\.id))
        for placement in level.solution {
            XCTAssertTrue(pieceIdSet.contains(placement.pieceId),
                          "Placement pieceId \(placement.pieceId) pieces'te bulunamadı")
        }
    }

    // MARK: - DifficultyPieceCount yardımcı

    func testDifficultyCurveValues() {
        // 5×5
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 5, levelIndex: 1), 4)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 5, levelIndex: 20), 4)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 5, levelIndex: 21), 5)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 5, levelIndex: 60), 5)
        // 6×6
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 6, levelIndex: 1), 5)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 6, levelIndex: 21), 6)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 6, levelIndex: 41), 7)
        // 7×7
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 7, levelIndex: 1), 6)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 7, levelIndex: 41), 8)
        // 8×8
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 8, levelIndex: 1), 8)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 8, levelIndex: 21), 10)
        XCTAssertEqual(gen.difficultyPieceCount(gridSize: 8, levelIndex: 41), 12)
    }
}
