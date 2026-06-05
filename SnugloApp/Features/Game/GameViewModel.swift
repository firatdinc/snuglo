import Foundation
import Observation
import SnugloEngine

typealias PieceID = String

// MARK: — MoveSnapshot

/// Records a single successful placement so it can be undone by PowerUp.undo.
/// Only the pieceID is needed: undo = removePlacement(pieceID) → piece returns to tray.
/// NOTE: moveCount is intentionally NOT decremented on undo — we track attempts, not board state.
struct MoveSnapshot {
    let pieceID: PieceID
}

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
    /// True once all pieces are placed without overlap/OOB.
    private(set) var isSolved: Bool = false

    // MARK: - Timer tracking
    /// Wall-clock time when this session started. Reset on restart.
    private(set) var startTime: Date = Date()

    // MARK: - Re-drag support

    /// Snapshot stored when a placed piece is lifted for re-dragging.
    /// Cleared on successful re-placement (commitLift) or restored on failure (rollbackLift).
    struct LiftSnapshot {
        let pieceID: PieceID
        let placement: Placement
    }
    private(set) var liftSnapshot: LiftSnapshot?

    // MARK: - Hint support

    /// Number of hints consumed in this session. Passed to LevelCompleteSheet.
    private(set) var hintsUsed: Int = 0
    /// The piece most recently placed by a hint — drives the GameView highlight.
    private(set) var lastHintPieceID: PieceID?

    // MARK: - Move tracking

    /// Count of successful placements this session (tray drops, re-drags, hints).
    private(set) var moveCount: Int = 0

    // MARK: - Achievement tracking

    /// Achievements newly unlocked upon solving this level.
    private(set) var newlyUnlockedAchievements: [Achievement] = []

    /// Clears the just-unlocked list once the view has queued its toasts.
    func clearNewAchievements() { newlyUnlockedAchievements = [] }

    // MARK: - PowerUp history

    /// Ordered list of successful placements — supports PowerUp.undo.
    /// Cleared on level start/restart (GameViewModel re-init handles this).
    private(set) var moveHistory: [MoveSnapshot] = []

    /// One free undo is granted per game session; resets on re-init (new game / restart).
    private(set) var freeUndoAvailable: Bool = true

    /// True when the just-solved campaign level beat the player's previous best time.
    private(set) var newBestTime: Bool = false

    /// True when the just-cleared endless level set a new personal-best run.
    private(set) var newEndlessBest: Bool = false

    /// Currency granted for the just-completed solve — computed & applied in
    /// `persistProgress` (where real stars + mode are known) and surfaced here so
    /// the result UI can display it without re-deriving rewards.
    private(set) var lastSolveReward: [Currency: Int] = [:]

    /// Relaxed contexts (Zen Mode or Endless) grant UNLIMITED free undo — these
    /// modes are about calm experimentation, not a gem sink. Timed campaign/daily
    /// keep the one-free-then-gem economy. Computed live so a mid-session Zen
    /// toggle is honoured.
    var unlimitedUndo: Bool {
        level.id.hasPrefix("endless") || UserDefaults.standard.bool(forKey: "zenMode")
    }

    // MARK: - Private
    private let checker = SolutionChecker()
    private let gameCenter: any GameCenterServicing

    // MARK: - Init

    init(level: Level, gameCenter: any GameCenterServicing = GameCenterManager.shared) {
        self.level = level
        self.startTime = Date()
        self.gameCenter = gameCenter
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
    /// levelId "daily" / "daily-N" → bugünün N. daily bölümü (çok-bölümlü challenge)
    /// levelId == "packId-index" → PackProvider.loadLevel(id:)
    @MainActor
    static func makeFromPackProvider(levelId: String) -> GameViewModel {
        let level: Level
        if levelId.hasPrefix("daily") {
            level = PackProvider.dailyPuzzle(index: PackProvider.dailyIndex(from: levelId))
        } else if levelId.hasPrefix("endless") {
            // Procedurally generated, ever-growing RELAXED run. Endless/Zen don't
            // need deterministic layouts (the endless leaderboard ranks the index
            // reached, not the exact boards), so we VARY the seed on every load —
            // otherwise each run replays the identical 1,2,3… boards and feels
            // repetitive. The difficulty curve (gridSize + index) is preserved.
            let n = Int(levelId.split(separator: "-").last ?? "1") ?? 1
            let g = min(7, 4 + (n - 1) / 4)
            let variedSeed = UInt64.random(in: UInt64.min ... UInt64.max)
            level = LevelGenerator().generate(packId: "endless", levelIndex: n, gridSize: g, seedBase: variedSeed)
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
    /// - Sets `isSolved = true` when all pieces fit exactly, then persists progress.
    func tryPlace(pieceID: PieceID, at coord: Coord) {
        let newPlacement = Placement(pieceId: pieceID, origin: coord)

        // Build candidate set (replace existing placement for same piece if any)
        var candidates = Array(placements.values).filter { $0.pieceId != pieceID }
        candidates.append(newPlacement)

        let result = checker.check(level: level, placements: candidates)

        // v1.1.3 debug: instrumented to investigate "KALAN 0 but not solved" report.
        let totalPieceCells = level.pieces.reduce(0) { $0 + $1.cells.count }
        let placedCellsAfter = candidates.reduce(0) { acc, p in
            acc + (level.pieces.first(where: { $0.id == p.pieceId })?.cells.count ?? 0)
        }
        NSLog("[Snuglo][tryPlace] level=\(level.id) pieceID=\(pieceID) placedSoFar=\(candidates.count)/\(level.pieces.count) cellsPlaced=\(placedCellsAfter)/\(totalPieceCells) gridArea=\(level.width * level.height) result=\(result)")

        switch result {
        case .valid:
            // All pieces placed, no conflicts → solved!
            placements[pieceID] = newPlacement
            invalidPieceIDs.remove(pieceID)
            moveCount += 1
            // Dedup: a re-dragged piece must appear once, at its LATEST placement
            // time — otherwise undo pops a stale duplicate and no-ops while the
            // user expects the next-most-recent piece to return to the tray.
            moveHistory.removeAll { $0.pieceID == pieceID }
            moveHistory.append(MoveSnapshot(pieceID: pieceID))
            isSolved = true
            NSLog("[Snuglo][tryPlace] SOLVED ✓")
            persistProgress()

        case .incompleteCoverage(let missing):
            // This placement is fine; more pieces still needed
            placements[pieceID] = newPlacement
            invalidPieceIDs.remove(pieceID)
            moveCount += 1
            // Dedup: a re-dragged piece must appear once, at its LATEST placement
            // time — otherwise undo pops a stale duplicate and no-ops while the
            // user expects the next-most-recent piece to return to the tray.
            moveHistory.removeAll { $0.pieceID == pieceID }
            moveHistory.append(MoveSnapshot(pieceID: pieceID))
            if missing.count <= 6 {
                NSLog("[Snuglo][tryPlace] missing cells: \(missing.map { "(\($0.x),\($0.y))" }.joined(separator: ","))")
            }

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
            persistProgress()
        }
    }

    /// Remove a piece from the grid (send back to tray).
    func removePlacement(for pieceID: PieceID) {
        placements.removeValue(forKey: pieceID)
        invalidPieceIDs.remove(pieceID)
        isSolved = false
    }

    // MARK: - Re-drag API

    /// Lift a placed piece off the board for re-dragging.
    /// Snapshots current placement so `rollbackLift()` can restore it on failed drop.
    func liftPiece(pieceID: PieceID) {
        guard let existing = placements[pieceID] else { return }
        liftSnapshot = LiftSnapshot(pieceID: pieceID, placement: existing)
        placements.removeValue(forKey: pieceID)
        invalidPieceIDs.remove(pieceID)
        isSolved = false
    }

    /// Restore the lifted piece to its original board position.
    /// Called when drop is invalid or finger released outside the grid.
    func rollbackLift() {
        guard let snapshot = liftSnapshot else { return }
        placements[snapshot.pieceID] = snapshot.placement
        invalidPieceIDs.remove(snapshot.pieceID)
        liftSnapshot = nil
    }

    /// Discard the snapshot after a successful re-placement.
    func commitLift() {
        liftSnapshot = nil
    }

    // MARK: - Hint API

    /// Use one hint to place the next unplaced piece at its correct solution position.
    ///
    /// Reuses `tryPlace` so win detection, logging, and persistence are unchanged.
    /// - Parameter store: ProgressStore instance; injectable for unit testing (default: `.shared`).
    /// - Returns: `true` if a hint was consumed and a piece was placed.
    @discardableResult
    func applyHint(store: ProgressStore = .shared) -> Bool {
        guard store.useHint() else { return false }
        hintsUsed += 1
        return placeHintPiece()
    }

    /// Places the first unplaced solution piece without consuming a hint token.
    /// Called by both `applyHint(store:)` (free path) and `applyPowerUp(.hint)` (gem path).
    @discardableResult
    private func placeHintPiece() -> Bool {
        guard let piece = unplacedPieces.first(where: { p in
            level.solution.contains(where: { $0.pieceId == p.id })
        }) else { return false }
        guard let solutionPlacement = level.solution.first(where: { $0.pieceId == piece.id })
        else { return false }
        lastHintPieceID = piece.id
        tryPlace(pieceID: piece.id, at: solutionPlacement.origin)
        return true
    }

    // MARK: - PowerUp API

    /// Returns true when `pu` can currently be applied (ignores affordability).
    func canApply(_ pu: PowerUp) -> Bool {
        PowerUpRules.isApplicable(
            pu,
            unplacedCount: unplacedPieces.count,
            moveHistoryCount: moveHistory.count
        )
    }

    /// Single orchestration point for all in-game power-ups.
    ///
    /// Hint follows a hybrid path: free inventory first, then gem spend.
    /// Undo does NOT decrement `moveCount` — attempts are permanent records.
    @discardableResult
    func applyPowerUp(
        _ pu: PowerUp,
        wallet: WalletStore = .shared,
        progress: ProgressStore = .shared
    ) -> PowerUpResult {
        guard canApply(pu) else { return .notApplicable }

        switch pu {
        case .hint:
            // Free inventory path.
            if progress.useHint() {
                if placeHintPiece() {
                    hintsUsed += 1
                    return .success
                }
                // Placement impossible despite passing canApply — refund the token.
                progress.addHints(1)
                return .notApplicable
            }
            // Gem fallback path.
            guard wallet.canAfford(.gem, amount: pu.gemCost) else { return .insufficientGem }
            guard wallet.spend(.gem, amount: pu.gemCost) else { return .insufficientGem }
            if placeHintPiece() {
                hintsUsed += 1
                return .success
            }
            // Placement impossible — refund the gem spend.
            wallet.earn(.gem, amount: pu.gemCost)
            return .notApplicable

        case .undo:
            // Relaxed modes: always free, never consumed.
            if unlimitedUndo {
                undoLastMove()
                return .success
            }
            // Free undo path — one per session.
            if freeUndoAvailable {
                freeUndoAvailable = false
                undoLastMove()
                return .success
            }
            // Gem fallback path.
            guard wallet.spend(.gem, amount: pu.gemCost) else { return .insufficientGem }
            undoLastMove()
            return .success

        case .shuffleTray:
            guard wallet.spend(.gem, amount: pu.gemCost) else { return .insufficientGem }
            shuffleTray()
            return .success
        }
    }

    /// Removes the most recent placement and returns the piece to the tray.
    func undoLastMove() {
        guard let snapshot = moveHistory.popLast() else { return }
        removePlacement(for: snapshot.pieceID)
        isSolved = false
    }

    /// Randomises the order of pieces remaining in the tray using Swift's
    /// built-in Fisher-Yates shuffle (seeded by SystemRandomNumberGenerator).
    private func shuffleTray() {
        // unplacedPieces is derived from level.pieces filtered by placements.
        // Shuffling level.pieces reorders how unplacedPieces are returned,
        // which TrayLayout consumes directly.
        var shuffled = level.pieces
        shuffled.shuffle()
        level = Level(
            id: level.id,
            width: level.width,
            height: level.height,
            pieces: shuffled,
            solution: level.solution
        )
    }

    /// Returns true if placing `pieceID` at `coord` would overlap an existing piece
    /// or land out-of-bounds. Used for real-time snap ghost validity feedback.
    func wouldOverlapOrOOB(pieceID: PieceID, at coord: Coord) -> Bool {
        let newPlacement = Placement(pieceId: pieceID, origin: coord)
        var candidates = Array(placements.values).filter { $0.pieceId != pieceID }
        candidates.append(newPlacement)
        switch checker.check(level: level, placements: candidates) {
        case .overlap, .outOfBounds, .unknownPiece: return true
        default: return false
        }
    }

    // MARK: - Persistence

    /// Called on solve. Writes level + daily progress to ProgressStore, evaluates achievements,
    /// then submits GC scores.
    /// Derive the pack id from a campaign level id ("<packId>-<index>").
    /// Strips the trailing "-<number>"; nil if the shape doesn't match.
    static func packId(from levelId: String) -> String? {
        let parts = levelId.split(separator: "-")
        guard parts.count >= 2, Int(parts.last!) != nil else { return nil }
        return parts.dropLast().joined(separator: "-")
    }

    private func persistProgress() {
        let timeTaken = Date().timeIntervalSince(startTime)
        let stars = computeStars(seconds: timeTaken, gridSize: level.width)
        let progress = ProgressStore.shared

        let isEndless = level.id.hasPrefix("endless")
        let isDaily   = level.id.hasPrefix("daily")
        // RELAXED = Endless OR Zen Mode (a global toggle that can also be on over a
        // campaign level). Relaxed play must not farm the economy.
        let relaxed   = isEndless || UserDefaults.standard.bool(forKey: "zenMode")

        // Did this campaign level already hold 3★ before now? (Captured BEFORE
        // markCompleted so the "first 3★" gem fires exactly once, ever.)
        var wasThreeStar = false

        if isDaily {
            // Daily levels are tracked per-day (dailyChallenge + streak), NOT in
            // levelProgress, so they never inflate the campaign "/240" counters
            // and reset cleanly each day.
            let idx = PackProvider.dailyIndex(from: level.id)
            progress.markDailyLevelSolved(index: idx, date: Date(), time: timeTaken)
        } else if isEndless {
            // Endless: track best run only — never inflate the campaign counters.
            let n = Int(level.id.split(separator: "-").last ?? "1") ?? 1
            newEndlessBest = EndlessStore.shared.record(index: n)
            // Endless earns no currency — its reward is the leaderboard.
            let best = EndlessStore.shared.best
            let gc = gameCenter
            Task { try? await gc.submit(score: best, leaderboardID: LeaderboardID.endlessBest) }
        } else {
            // Capture the prior best/stars BEFORE markCompleted overwrites them.
            let prevBest = progress.levelProgress[level.id]?.bestTime
            wasThreeStar = (progress.levelProgress[level.id]?.stars ?? 0) >= 3
            newBestTime = prevBest != nil && timeTaken < prevBest!
            progress.markCompleted(levelId: level.id, stars: stars, time: timeTaken, hintsUsed: hintsUsed)
            // Pack completion milestone: reward finishing every level in a pack.
            if let packId = Self.packId(from: level.id),
               let total = MockData.allPacks.first(where: { $0.id == packId })?.levelCount {
                PackRewardStore.shared.checkCompletion(
                    packId: packId,
                    totalLevels: total,
                    completed: progress.packCompletionCount(packId)
                )
            }
        }

        // ── Rewards ─────────────────────────────────────────────────────────
        let wallet = WalletStore.shared
        if relaxed {
            // Tiny daily-capped XP/coin, never gems, and no economy-meter / score
            // progress — relaxed modes are for calm, not farming.
            let granted = RelaxedRewardStore.shared.grant()
            if granted.xp > 0 { XPStore.shared.award(granted.xp) }
            if granted.coin > 0 { wallet.earn(.coin, amount: granted.coin) }
            lastSolveReward = granted.coin > 0 ? [.coin: granted.coin] : [:]
        } else {
            // Campaign / Daily: coin scales with REAL stars (+ small speed bonus);
            // a single gem ONLY the first time a campaign level reaches 3★
            // (skill-gated and finite — gems stay scarce/valuable).
            let coin = max(0, stars) * 10 + (timeTaken < 60 ? 5 : 0)
            let gem  = (!isDaily && !wasThreeStar && stars >= 3) ? 1 : 0
            if coin > 0 { wallet.earn(.coin, amount: coin) }
            if gem  > 0 { wallet.earn(.gem,  amount: gem) }
            var r: [Currency: Int] = [:]
            if coin > 0 { r[.coin] = coin }
            if gem  > 0 { r[.gem]  = gem }
            lastSolveReward = r
            // XP: base + star bonus → player level progression.
            XPStore.shared.award(20 + stars * 10)
            // Economy meters advance on real play only.
            DailyQuestStore.shared.recordSolve(seconds: Int(timeTaken), hintsUsed: hintsUsed, stars: stars)
            ChestStore.shared.recordSolve()
            WeeklyChallengeStore.shared.recordSolve()
        }

        let stats = AchievementStats(from: progress)
        let unlockedNow = AchievementsStore.shared.evaluate(stats: stats, wallet: wallet)
        newlyUnlockedAchievements = unlockedNow
        // Mirror freshly-unlocked achievements to Game Center (fire-and-forget).
        if !unlockedNow.isEmpty {
            let gc = gameCenter
            Task { for a in unlockedNow { await gc.report(achievementID: a.gcID, percentComplete: 100) } }
        }
        if !relaxed { submitScores() }
    }

    private func submitScores() {
        let gc = gameCenter
        Task {
            let progress = ProgressStore.shared
            let totalLevels = GameCenterScoreMapper.totalLevels(
                completedCount: progress.totalLevelsCompleted()
            )
            let bestTimes = progress.levelProgress.values.compactMap(\.bestTime)
            let fastestMs = GameCenterScoreMapper.fastestSolveMs(fromBestTimes: bestTimes)
            let streak = GameCenterScoreMapper.bestStreak(progress.longestStreak)

            try? await gc.submit(score: totalLevels, leaderboardID: LeaderboardID.totalLevels)
            if let ms = fastestMs {
                try? await gc.submit(score: ms, leaderboardID: LeaderboardID.fastestSolve)
            }
            try? await gc.submit(score: streak, leaderboardID: LeaderboardID.bestStreak)
        }
    }

    // MARK: - Star Calculation

    /// Stars based on solve time relative to grid complexity.
    ///
    /// Thresholds (gridSize → base):
    ///   5×5 → 30 s   |  3 stars: ≤30s  2: ≤60s  1: else
    ///   6×6 → 60 s   |  3 stars: ≤60s  2: ≤120s 1: else
    ///   7×7 → 90 s   |  3 stars: ≤90s  2: ≤180s 1: else
    ///   8×8 → 120 s  |  3 stars: ≤120s 2: ≤240s 1: else
    static func computeStars(seconds: TimeInterval, gridSize: Int) -> Int {
        let base = Double(max(gridSize - 4, 1)) * 30.0   // 30, 60, 90, 120 for 5-8
        if seconds <= base { return 3 }
        if seconds <= base * 2.0 { return 2 }
        return 1
    }

    private func computeStars(seconds: TimeInterval, gridSize: Int) -> Int {
        GameViewModel.computeStars(seconds: seconds, gridSize: gridSize)
    }
}
