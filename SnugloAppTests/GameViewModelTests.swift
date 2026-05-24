// GameViewModelTests.swift — v0.2 GameViewModel unit testleri
// Senaryo 1: load    — level_5x5 yüklenir, boyutlar doğrulanır
// Senaryo 2: place   — geçerli origin'e yerleştirme çalışır
// Senaryo 3: solved  — tüm parçalar solution origin'lerine yerleşince isSolved == true

import XCTest
import SnugloEngine
@testable import Snuglo

final class GameViewModelTests: XCTestCase {

    private var sut: GameViewModel!

    override func setUp() {
        super.setUp()
        sut = GameViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 1. Load

    func testLoad_level5x5_parsedCorrectly() {
        // Act
        sut.loadLevel(named: "level_5x5")

        // Assert
        XCTAssertNil(sut.loadError, "Yükleme hatası beklenmiyor: \(sut.loadError ?? "")")
        XCTAssertNotNil(sut.level, "Level nil olmamalı")
        XCTAssertEqual(sut.level?.id, "level_5x5")
        XCTAssertEqual(sut.level?.width,  5)
        XCTAssertEqual(sut.level?.height, 5)
        XCTAssertEqual(sut.level?.pieces.count, 5, "level_5x5 beş parça içermeli")
    }

    // MARK: - 2. Place

    func testPlace_firstPieceAtValidOrigin_succeeds() {
        // Arrange
        sut.loadLevel(named: "level_5x5")
        guard let level = sut.level else {
            XCTFail("Level yüklenemedi"); return
        }
        let firstSolution = level.solution.first!

        // Act
        let result = sut.place(pieceId: firstSolution.pieceId, at: firstSolution.origin)

        // Assert
        XCTAssertTrue(result, "Geçerli yerleşim true dönmeli")
        XCTAssertEqual(sut.placements.count, 1)
        XCTAssertNotNil(sut.placements[firstSolution.pieceId])
        XCTAssertFalse(sut.isSolved, "Sadece 1 parça yerleştirildi; henüz çözülmüş sayılmamalı")
    }

    // MARK: - 3. Solved

    func testSolved_allPiecesAtSolutionOrigins_isSolvedTrue() {
        // Arrange
        sut.loadLevel(named: "level_5x5")
        guard let level = sut.level else {
            XCTFail("Level yüklenemedi"); return
        }

        // Act: tüm parçaları referans çözümdeki konumlara yerleştir
        for placement in level.solution {
            let ok = sut.place(pieceId: placement.pieceId, at: placement.origin)
            XCTAssertTrue(ok, "Parça '\(placement.pieceId)' geçerli konuma yerleştirilemedi")
        }

        // Assert
        XCTAssertEqual(sut.placements.count, level.pieces.count, "Tüm parçalar yerleştirilmiş olmalı")
        XCTAssertTrue(sut.isSolved, "Tüm parçalar yerleşince isSolved true olmalı")
    }
}
