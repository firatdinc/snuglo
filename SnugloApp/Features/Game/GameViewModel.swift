import Foundation
import Observation
import SnugloEngine

typealias PieceID = String

/// Core game state machine for a single level session.
///
/// @MainActor — all properties read/written from the main thread (SwiftUI).
@MainActor
@Observable
final class GameViewModel {

    // MARK: - Published state
    private(set) var level: Level
    /// Accepted placements: pieceID → Placement
    private(set) var placements: [PieceID: Placement] = [:]
    /// Pieces whose last tryPlace was rejected (overlap / OOB).
    private(set) var invalidPieceIDs: Set<PieceID> = []
    /// True once all pieces are placed without overlap/OOB (prints "Solved!").
    private(set) var isSolved: Bool = false

    // MARK: - Private
    private let checker = SolutionChecker()

    // MARK: - Init

    init(level: Level) {
        self.level = level
    }

    /// Load from SnugloEngine bundle. Throws LevelLoader.LoaderError on failure.
    static func make(levelNamed name: String = "level_5x5") throws -> GameViewModel {
        let level = try LevelLoader().loadLevel(named: name)
        return GameViewModel(level: level)
    }

    /// Non-throwing convenience — returns a fallback 1×1 level on error.
    static func makeOrFallback(levelNamed name: String = "level_5x5") -> GameViewModel {
        if let vm = try? make(levelNamed: name) { return vm }
        let fallback = Level(
            id: "fallback", width: 1, height: 1,
            pieces: [Piece(id: "p1", cells: [Coord(x: 0, y: 0)])],
            solution: [Placement(pieceId: "p1", origin: Coord(x: 0, y: 0))]
        )
        return GameViewModel(level: fallback)
    }

    /// Faz D-2: PackProvider üzerinden engine Level ile başlat.
    /// levelId == "daily" → bugünün DailyPuzzle'ı
    /// levelId == "packId-index" → PackProvider.loadLevel(id:)
    @MainActor
    static func makeFromPackProvider(levelId: String) -> GameViewModel {
        let level: Level
        if levelId == "daily" {
            level = PackProvider.dailyPuzzle()
        } else {
            level = PackProvider.loadLevel(id: levelId) ?? PackProvider.dailyPuzzle()
        }
        return GameViewModel(level: level)
    }

    // MARK: - Computed helpers

    /// Pieces not yet successfully placed on the grid.
    var unplacedPieces: [Piece] {
        level.pieces.filter { placements[$0.id] == nil }
    }

    // MARK: - Actions

    /// Attempt to place `pieceID` with its origin at `coord`.
    ///
    /// - Accepts if the resulting set of placements has no overlap / OOB.
    /// - Rejects (adds to `invalidPieceIDs`) on overlap, out-of-bounds, or unknown piece.
    /// - Sets `isSolved = true` and prints "Solved!" when all pieces fit exactly.
    func tryPlace(pieceID: PieceID, at coord: Coord) {
        let newPlacement = Placement(pieceId: pieceID, origin: coord)

        // Build candidate set (replace existing placement for same piece if any)
        var candidates = Array(placements.values).filter { $0.pieceId != pieceID }
        candidates.append(newPlacement)

        let result = checker.check(level: level, placements: candidates)

        switch result {
        case .valid:
            // All pieces placed, no conflicts → solved!
            placements[pieceID] = newPlacement
            invalidPieceIDs.remove(pieceID)
            isSolved = true
            print("Solved!")

        case .incompleteCoverage:
            // This placement is fine; more pieces still needed
            placements[pieceID] = newPlacement
            invalidPieceIDs.remove(pieceID)

        case .overlap, .outOfBounds, .unknownPiece:
            // Reject — caller should animate the block back
            invalidPieceIDs.insert(pieceID)

        case .emptyGrid:
            break
        }
    }

    /// Clear the invalid flag (call after ease-back animation completes).
    func clearInvalid(pieceID: PieceID) {
        invalidPieceIDs.remove(pieceID)
    }

    /// Re-check solved state (safe to call redundantly).
    func checkSolved() {
        let all = Array(placements.values)
        guard all.count == level.pieces.count else { return }
        if checker.check(level: level, placements: all) == .valid {
            isSolved = true
            print("Solved!")
        }
    }

    /// Remove a piece from the grid (send back to tray).
    func removePlacement(for pieceID: PieceID) {
        placements.removeValue(forKey: pieceID)
        invalidPieceIDs.remove(pieceID)
        isSolved = false
    }
}
