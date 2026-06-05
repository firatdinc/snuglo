import Foundation
import Observation

// MARK: — GameCenterAuthState

enum GameCenterAuthState: Equatable {
    case idle
    case authenticating
    case signedIn(displayName: String)
    case notSignedIn
    case error(String)
}

// MARK: — GameCenterEntry

struct GameCenterEntry: Identifiable, Equatable {
    let id: String
    let rank: Int
    let displayName: String
    let score: Int
    let isLocalPlayer: Bool
    let isSimulated: Bool
}

// MARK: — GameCenterServicing

@MainActor
protocol GameCenterServicing: AnyObject, Observable {
    var authState: GameCenterAuthState { get }
    func authenticate() async
    func submit(score: Int, leaderboardID: String) async throws
    func loadEntries(for leaderboardID: String) async throws -> [GameCenterEntry]
    /// Reports an achievement's completion to Game Center. Fire-and-forget —
    /// failures (offline, not signed in) are swallowed, never surfaced to gameplay.
    func report(achievementID: String, percentComplete: Double) async
}
