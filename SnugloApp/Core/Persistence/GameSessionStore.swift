import Foundation
import SnugloEngine

// MARK: — GameSession
// A resumable snapshot of an in-progress level: which pieces are on the board,
// the clock, and the counters needed to keep stars/undo correct on resume.
//
// `fingerprint` pins the snapshot to the exact level layout it was taken on, so a
// stale session can never be restored onto a different board (e.g. the daily
// puzzle rolling over to a new day reuses the "daily-0" id but changes content).
struct GameSession: Codable {
    var levelID: String
    var fingerprint: String
    var placements: [Placement]
    var elapsedSeconds: Int
    var moveCount: Int
    var hintsUsed: Int
    var moveHistory: [String]   // pieceIDs, in placement order (for undo)
}

// MARK: — GameSessionStore
// Persists in-progress level sessions so leaving a level (and coming back, even
// after an app restart) resumes the board exactly where it was left — paired with
// EnergyStore's "no double-charge on re-entry" so an attempt is paid for once.
//
// Only deterministic levels are resumable (campaign + daily); Endless/Tower roll a
// fresh random seed each load and are never saved here.

@MainActor
final class GameSessionStore {

    static let shared = GameSessionStore()

    private let defaults: UserDefaults
    private let key = "snuglo.gamesessions.v1"
    private var sessions: [String: GameSession]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: GameSession].self, from: data) {
            sessions = decoded
        } else {
            sessions = [:]
        }
    }

    func session(for levelID: String) -> GameSession? { sessions[levelID] }

    func save(_ session: GameSession) {
        sessions[session.levelID] = session
        persist()
    }

    func clear(levelID: String) {
        guard sessions.removeValue(forKey: levelID) != nil else { return }
        persist()
    }

    /// Wipe ALL saved in-progress sessions. Used by Reset Progress so a reset
    /// player doesn't resume onto a board from before the wipe.
    func clearAll() {
        guard !sessions.isEmpty else { return }
        sessions.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            defaults.set(data, forKey: key)
        }
    }
}
