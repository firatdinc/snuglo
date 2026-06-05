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

    // Bridges authenticateHandler callback to async/await. @ObservationIgnored because
    // CheckedContinuation is non-Sendable and must not be tracked by the @Observable macro.
    @ObservationIgnored
    private var authContinuation: CheckedContinuation<Void, Never>?

    private init() {}

    // MARK: — Authentication

    func authenticate() async {
        if case .signedIn   = authState { return }
        if case .authenticating = authState { return }
        // Don't retry after a permanent GK error (e.g. app not registered in ASC).
        // Repeated retries fire the authenticateHandler callback on the main thread
        // and generate log noise without any chance of succeeding.
        if case .error = authState { return }
        authState = .authenticating

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            authContinuation = cont
            // authenticateHandler fires once immediately (possibly with vc on first run),
            // then again after any presented UI is dismissed. We only update state, never
            // present the vc — iOS 17+ handles Game Center sign-in at the system level.
            GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.authState = .error(error.localizedDescription)
                        // Clear the handler after a permanent failure so GK stops
                        // firing callbacks and spamming the main thread.
                        GKLocalPlayer.local.authenticateHandler = nil
                    } else if GKLocalPlayer.local.isAuthenticated {
                        self.authState = .signedIn(displayName: GKLocalPlayer.local.displayName)
                    } else {
                        self.authState = .notSignedIn
                    }
                    // Resume exactly once; nil-out prevents double-resume on subsequent handler fires.
                    self.authContinuation?.resume()
                    self.authContinuation = nil
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

    // MARK: — Achievement reporting

    func report(achievementID: String, percentComplete: Double) async {
        guard case .signedIn = authState else { return }
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        try? await GKAchievement.report([achievement])
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
