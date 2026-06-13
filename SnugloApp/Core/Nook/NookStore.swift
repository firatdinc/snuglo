import Foundation
import Observation

// MARK: — NookStore
// Progress for the cozy meta-layer, reimagined as scene restoration. Every
// campaign pack owns a scene (PackArt.theme(forPackId:).scene). The scene starts
// as a dark silhouette split into 6 pieces; the player earns the RIGHT to place
// one piece every 10 levels (levels 10/20/…/60) and drags it into the picture,
// revealing that region in full colour. Restoring all 6 = the pack's scene is
// whole and its mascot is rescued.
//
// "Earned" pieces are DERIVED from campaign progress (packCompletionCount / 10)
// so they can never desync — no runtime award hook needed. Only "placed" counts
// are persisted (a Codable snapshot in UserDefaults, decodeIfPresent for
// forward/back-compat). Mascots stay derived from full pack completion.

@Observable
@MainActor
final class NookStore {

    static let shared = NookStore()

    /// packId → number of scene pieces the player has dragged into place (0…6).
    private(set) var placed: [String: Int]

    /// Pieces a scene is split into, and how many levels earn one piece.
    static let piecesPerScene = 6
    static let levelsPerPiece = 10

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "snuglo.nook.v2") {
        self.defaults = defaults
        self.key = key
        self.placed = [:]
        load()
    }

    // MARK: — Pieces (earned = derived from progress, placed = persisted)

    /// How many pieces the player has unlocked the right to place — one per 10
    /// completed levels in the pack, capped at the 6 the scene splits into.
    func earnedPieces(_ packId: String) -> Int {
        let done = ProgressStore.shared.packCompletionCount(packId)
        return min(Self.piecesPerScene, done / Self.levelsPerPiece)
    }

    /// How many pieces are already dragged into the scene.
    func placedPieces(_ packId: String) -> Int {
        min(Self.piecesPerScene, placed[packId] ?? 0)
    }

    /// Pieces earned but not yet placed — these sit in the tray, ready to drag.
    func availablePieces(_ packId: String) -> Int {
        max(0, earnedPieces(packId) - placedPieces(packId))
    }

    /// True once every piece of the pack's scene is in place.
    func isRestored(_ packId: String) -> Bool {
        placedPieces(packId) >= Self.piecesPerScene
    }

    /// Place the next available piece (sequential: index == current placed count).
    /// Returns the index just placed (0-based), or nil if none was available.
    @discardableResult
    func placeNextPiece(_ packId: String) -> Int? {
        let current = placedPieces(packId)
        guard current < earnedPieces(packId) else { return nil }
        placed[packId] = current + 1
        save()
        return current
    }

    /// Total pieces ready to place across every pack — drives the menu badge.
    var totalAvailablePieces: Int {
        MockData.allPacks.reduce(0) { $0 + availablePieces($1.id) }
    }

    /// Wipe all placed scene pieces. Called by Reset Progress — earned pieces are
    /// derived from campaign progress (which is reset too), so the scenes go back to
    /// full silhouettes.
    func reset() {
        placed = [:]
        save()
    }

    // MARK: — Mascots (derived from full pack completion)

    /// A mascot is rescued once its pack is fully completed.
    func isMascotUnlocked(_ packId: String) -> Bool {
        guard let pack = MockData.allPacks.first(where: { $0.id == packId }) else { return false }
        return ProgressStore.shared.packCompletionCount(packId) >= pack.levelCount
    }

    var unlockedMascotCount: Int {
        NookCatalog.mascots.reduce(0) { $0 + (isMascotUnlocked($1.packId) ? 1 : 0) }
    }

    // MARK: — Progress

    /// 0.0–1.0 across every scene piece in the game — drives the "your world is
    /// X% restored" meter that gives a long-term reason to keep solving.
    var completion: Double {
        let total = MockData.allPacks.count * Self.piecesPerScene
        guard total > 0 else { return 0 }
        let done = MockData.allPacks.reduce(0) { $0 + placedPieces($1.id) }
        return min(1.0, Double(done) / Double(total))
    }

    // MARK: — Persistence

    private struct Snapshot: Codable {
        var placed: [String: Int]

        init(placed: [String: Int]) { self.placed = placed }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            placed = try c.decodeIfPresent([String: Int].self, forKey: .placed) ?? [:]
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        placed = snap.placed
    }

    private func save() {
        let snap = Snapshot(placed: placed)
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
        }
    }
}
