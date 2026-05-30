import Foundation
import GameKit
import Observation

// MARK: — GameCenterManager
// Production implementation of GameCenterServicing.
// Uses modern async/await GameKit APIs (iOS 14+).
// Auth uses the authenticateHandler pattern because GameKit has no async auth equivalent.

@Observable
@MainActor
final class GameCenterManager: GameCenterServicing {

    static let shared = GameCenterManager()

    private(set) var authState: GameCenterAuthState = .idle

    private init() {}

    // MARK: — Authentication

    func authenticate() async {
        if case .signedIn = authState { return }
        if case .authenticating = authState { return }
        authState = .authenticating

        // authenticateHandler fires once immediately (possibly with vc on first run),
        // then again after any presented UI is dismissed. We only update state, never
        // present the vc — iOS 17+ handles Game Center sign-in at the system level.
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.authState = .error(error.localizedDescription)
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.authState = .signedIn(displayName: GKLocalPlayer.local.displayName)
                } else {
                    self.authState = .notSignedIn
                }
            }
        }
    }

    // MARK: — Score submission

    func submit(score: Int, leaderboardID: String) async throws {
        guard case .signedIn = authState else { return }
        guard score > 0 else { return }
        try await GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        )
    }

    // MARK: — Entry loading

    func loadEntries(for leaderboardID: String) async throws -> [GameCenterEntry] {
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
        guard let board = boards.first else { return [] }

        let result = try await board.loadEntries(
            for: .global,
            timeScope: .allTime,
            range: NSRange(location: 1, length: 25)
        )

        let localID = GKLocalPlayer.local.gamePlayerID
        var entries: [GameCenterEntry] = result.1.map { entry in
            GameCenterEntry(
                id: entry.player.gamePlayerID,
                rank: entry.rank,
                displayName: entry.player.displayName,
                score: entry.score,
                isLocalPlayer: entry.player.gamePlayerID == localID,
                isSimulated: false
            )
        }

        // Append local player entry if outside the top range
        if let local = result.0, !entries.contains(where: { $0.isLocalPlayer }) {
            entries.append(GameCenterEntry(
                id: local.player.gamePlayerID,
                rank: local.rank,
                displayName: local.player.displayName,
                score: local.score,
                isLocalPlayer: true,
                isSimulated: false
            ))
        }

        return entries
    }
}
