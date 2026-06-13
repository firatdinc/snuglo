import Foundation
import Observation

// MARK: — TowerStore
// Tracks the best Tower climb (highest floor cleared). The Tower is a
// ticket-gated, one-mistake-ends-the-run mode: each floor is a procedurally
// generated puzzle that gets harder as you climb. Self-contained UD key.

@Observable
@MainActor
final class TowerStore {

    static let shared = TowerStore()

    /// Entry cost, in tickets, to start (or retry) a climb.
    static let ticketCost = 1

    private(set) var bestFloor: Int
    /// Floor of the CURRENT in-progress climb (0 = no active run). Persisted so a
    /// climb resumes where you left off after closing the app.
    private(set) var currentFloor: Int

    private let defaults: UserDefaults
    private let key = "snuglo.tower.bestFloor.v1"
    private let currentKey = "snuglo.tower.currentFloor.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bestFloor = defaults.integer(forKey: key)
        currentFloor = defaults.integer(forKey: currentKey)
    }

    /// True when a climb is in progress and can be resumed without a ticket.
    var hasActiveRun: Bool { currentFloor > 0 }

    /// Mark the floor the player is currently on (persisted for resume).
    func setCurrentFloor(_ floor: Int) {
        currentFloor = max(0, floor)
        defaults.set(currentFloor, forKey: currentKey)
    }

    /// End the active climb (eliminated / went home for good).
    func endRun() { setCurrentFloor(0) }

    /// Record clearing `floor`; keeps the best. Returns true on a new record.
    @discardableResult
    func record(floor: Int) -> Bool {
        guard floor > bestFloor else { return false }
        bestFloor = floor
        defaults.set(bestFloor, forKey: key)
        return true
    }

    /// Grid size for a tower floor — climbs 5×5 → 8×8 as you go higher.
    static func gridSize(forFloor floor: Int) -> Int {
        min(8, 5 + (max(1, floor) - 1) / 4)
    }

    /// Coin reward for ending a run having cleared `floors` floors.
    static func reward(forFloors floors: Int) -> Int {
        max(0, floors) * 20
    }

    /// Can the player afford a climb right now?
    func canEnter(wallet: WalletStore = .shared) -> Bool {
        wallet.canAfford(.ticket, amount: Self.ticketCost)
    }

    /// Spend the entry ticket. Returns success.
    @discardableResult
    func payEntry(wallet: WalletStore = .shared) -> Bool {
        wallet.spend(.ticket, amount: Self.ticketCost)
    }
}
