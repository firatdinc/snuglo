import Foundation
import Observation

// MARK: — LeaderboardLoadState

enum LeaderboardLoadState: Equatable {
    case idle
    case loading
    case loaded([GameCenterEntry])
    case empty
    case notSignedIn
    case error(String)
}

// MARK: — LeaderboardViewModel

@Observable
@MainActor
final class LeaderboardViewModel {

    // MARK: — State

    var selectedBoard: String = LeaderboardID.totalLevels
    private(set) var loadState: LeaderboardLoadState = .idle

    // MARK: — DI

    private let gameCenterService: any GameCenterServicing
    private let progress: ProgressStore

    // MARK: — Init

    init(
        gameCenter: any GameCenterServicing = GameCenterManager.shared,
        progress: ProgressStore = .shared
    ) {
        self.gameCenterService = gameCenter
        self.progress = progress
    }

    // MARK: — Load

    func load() async {
        loadState = .loading
        if case .idle = gameCenterService.authState { await gameCenterService.authenticate() }

        switch gameCenterService.authState {
        case .signedIn:
            do {
                let entries = try await gameCenterService.loadEntries(for: selectedBoard)
                loadState = entries.isEmpty ? .empty : .loaded(entries)
            } catch {
                loadState = .error(error.localizedDescription)
            }
        case .error(let msg):
            loadState = .error(msg)
        default:
            loadState = .notSignedIn
        }
    }

    // MARK: — Fallback entries (local + simulated competitors)

    var fallbackEntries: [GameCenterEntry] {
        let boardID = selectedBoard
        var all = simulatedPlayers(boardID: boardID)
        all.append(localEntry(boardID: boardID))
        all.sort { isHigherRanked($0.score, than: $1.score, boardID: boardID) }
        return all.enumerated().map { idx, entry in
            GameCenterEntry(
                id: entry.id,
                rank: idx + 1,
                displayName: entry.displayName,
                score: entry.score,
                isLocalPlayer: entry.isLocalPlayer,
                isSimulated: entry.isSimulated
            )
        }
    }

    // MARK: — Helpers

    private func localEntry(boardID: String) -> GameCenterEntry {
        let name: String
        if case .signedIn(let displayName) = gameCenterService.authState { name = displayName } else { name = "You" }
        return GameCenterEntry(
            id: "local.player",
            rank: 0,
            displayName: name,
            score: localScore(boardID: boardID),
            isLocalPlayer: true,
            isSimulated: false
        )
    }

    private func localScore(boardID: String) -> Int {
        switch boardID {
        case LeaderboardID.totalLevels:
            return progress.totalLevelsCompleted()
        case LeaderboardID.fastestSolve:
            let times = progress.levelProgress.values.compactMap(\.bestTime)
            return GameCenterScoreMapper.fastestSolveCentiseconds(fromBestTimes: times) ?? 0
        case LeaderboardID.bestStreak:
            return GameCenterScoreMapper.bestStreak(progress.longestStreak)
        case LeaderboardID.endlessBest:
            return max(0, EndlessStore.shared.best)
        default:
            return 0
        }
    }

    private func simulatedPlayers(boardID: String) -> [GameCenterEntry] {
        let names = ["PuzzlePro", "CozyGamer", "SnugMaster", "QuietSolver"]
        let scores: [Int]
        switch boardID {
        case LeaderboardID.fastestSolve:
            scores = [1200, 2100, 2800, 3500]
        case LeaderboardID.bestStreak:
            scores = [30, 18, 12, 7]
        default:
            scores = [60, 45, 30, 20]
        }
        return zip(names, scores).map { name, score in
            GameCenterEntry(
                id: "sim.\(name.lowercased())",
                rank: 0,
                displayName: name,
                score: score,
                isLocalPlayer: false,
                isSimulated: true
            )
        }
    }

    private func isHigherRanked(_ lhs: Int, than rhs: Int, boardID: String) -> Bool {
        if boardID == LeaderboardID.fastestSolve {
            if lhs == 0 { return false }
            if rhs == 0 { return true }
            return lhs < rhs
        }
        return lhs > rhs
    }
}
