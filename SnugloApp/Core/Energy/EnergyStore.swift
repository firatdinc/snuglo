import Foundation
import Observation

// MARK: — EnergyStore
// Energy gate that limits how often free players can start games (pushing them
// toward Premium, which is unlimited). Timestamp-based regen so it survives the
// app being backgrounded/quit: on every read we compute how much energy has
// regenerated since the stored anchor.
//
// Rules:
//   • Max 50 energy
//   • Each new game costs 5
//   • +1 energy every 3 minutes
//   • Premium players bypass it entirely (always full, never charged)
//   • UI-test runs bypass it (deterministic flows)

@Observable
@MainActor
final class EnergyStore {

    static let shared = EnergyStore()

    static let maxEnergy: Int = 50
    static let costPerGame: Int = 5
    static let regenSeconds: TimeInterval = 180   // 3 minutes per energy

    // Persisted: the stored energy value and the anchor it was measured from.
    private let defaults: UserDefaults
    private let energyKey = "snuglo.energy.value.v1"
    private let anchorKey = "snuglo.energy.anchor.v1"
    private let openLevelsKey = "snuglo.energy.openlevels.v1"

    // Paid levels the player has started but not yet finished. Re-entering one of
    // these (left the level, came back) must NOT charge energy a second time — you
    // already paid for this attempt. Cleared on completion via endPaidSession().
    @ObservationIgnored private var openPaidLevels: Set<String>

    /// Energy spent on the most recent paid game start that the next game screen
    /// should animate (0 = nothing pending). Consumed once by GameView on appear —
    /// kept out of observation so reading it never triggers a render.
    @ObservationIgnored var pendingSpendAnimation: Int = 0

    // Mutated by refresh() (called from view bodies via TimelineView ticks), so
    // kept out of observation to avoid a render→mutate→render loop. UI that shows
    // energy drives its updates from a TimelineView, not from observation.
    @ObservationIgnored private var storedEnergy: Int
    @ObservationIgnored private var anchor: Date

    // Premium / bypass providers (injectable for tests).
    var isPremiumProvider: () -> Bool = { StoreManager.shared.isPremium }
    var isBypassedProvider: () -> Bool = {
        UserDefaults.standard.bool(forKey: "snuglo.uitestmode")
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: energyKey) != nil {
            storedEnergy = max(0, defaults.integer(forKey: energyKey))
            let t = defaults.double(forKey: anchorKey)
            anchor = t > 0 ? Date(timeIntervalSince1970: t) : Date()
        } else {
            storedEnergy = Self.maxEnergy
            anchor = Date()
        }
        openPaidLevels = Set(defaults.stringArray(forKey: openLevelsKey) ?? [])
    }

    // MARK: - Derived state

    private var unlimited: Bool { isPremiumProvider() || isBypassedProvider() }

    /// Current energy, after applying any regen accrued since the anchor.
    /// Mutates+persists when whole energy units have regenerated.
    @discardableResult
    func refresh(now: Date = Date()) -> Int {
        if unlimited { return Self.maxEnergy }
        if storedEnergy >= Self.maxEnergy {
            anchor = now          // full → regen clock paused
            return storedEnergy
        }
        let elapsed = now.timeIntervalSince(anchor)
        guard elapsed > 0 else { return storedEnergy }
        let gained = Int(elapsed / Self.regenSeconds)
        if gained > 0 {
            storedEnergy = min(Self.maxEnergy, storedEnergy + gained)
            anchor = anchor.addingTimeInterval(Double(gained) * Self.regenSeconds)
            if storedEnergy >= Self.maxEnergy { anchor = now }
            persist()
        }
        return storedEnergy
    }

    var current: Int { refresh() }
    var isFull: Bool { unlimited || refresh() >= Self.maxEnergy }
    var canStartGame: Bool { unlimited || refresh() >= Self.costPerGame }

    /// Seconds until the next single energy point regenerates (0 if full/premium).
    func secondsUntilNext(now: Date = Date()) -> Int {
        if unlimited { return 0 }
        _ = refresh(now: now)
        if storedEnergy >= Self.maxEnergy { return 0 }
        let into = now.timeIntervalSince(anchor).truncatingRemainder(dividingBy: Self.regenSeconds)
        return max(0, Int(ceil(Self.regenSeconds - into)))
    }

    /// Seconds until there's enough energy to start a game (0 if already enough).
    func secondsUntilPlayable(now: Date = Date()) -> Int {
        if unlimited || canStartGame { return 0 }
        let needed = Self.costPerGame - refresh(now: now)
        guard needed > 0 else { return 0 }
        let into = now.timeIntervalSince(anchor).truncatingRemainder(dividingBy: Self.regenSeconds)
        let toNext = Self.regenSeconds - into
        return max(0, Int(ceil(toNext + Double(needed - 1) * Self.regenSeconds)))
    }

    // MARK: - Mutations

    /// Spend the cost of one game if affordable (or premium). Returns success.
    ///
    /// Pass `levelID` for campaign levels so re-entering an unfinished paid level
    /// (you left and came back) doesn't charge twice — you already paid for this
    /// attempt. Relaxed/Endless/Tower starts pass nil (they're free anyway).
    @discardableResult
    func startGameIfAffordable(levelID: String? = nil) -> Bool {
        if unlimited { return true }
        // Re-entry to a level whose paid attempt is still open → free.
        if let id = levelID, openPaidLevels.contains(id) { return true }
        _ = refresh()
        guard storedEnergy >= Self.costPerGame else { return false }
        // Leaving "full" → start the regen clock from now.
        if storedEnergy >= Self.maxEnergy { anchor = Date() }
        storedEnergy -= Self.costPerGame
        if let id = levelID { openPaidLevels.insert(id) }
        pendingSpendAnimation = Self.costPerGame   // GameView animates this once
        persist()
        return true
    }

    /// Charge for an explicit RESTART of an in-progress paid level. A restart is a
    /// brand-new attempt, so it costs energy again — but the level stays "open" so a
    /// later leave/return still isn't double-charged. Returns false (no mutation) when
    /// the player can't afford it; the caller should route to the energy gate / a
    /// rewarded ad instead of restarting for free.
    @discardableResult
    func chargeRestart(levelID: String) -> Bool {
        if unlimited { return true }
        _ = refresh()
        guard storedEnergy >= Self.costPerGame else { return false }
        if storedEnergy >= Self.maxEnergy { anchor = Date() }
        storedEnergy -= Self.costPerGame
        openPaidLevels.insert(levelID)        // keep marked paid (idempotent)
        pendingSpendAnimation = Self.costPerGame
        persist()
        return true
    }

    /// Consume the pending spend amount for the spend animation (returns 0 if none).
    func consumeSpendAnimation() -> Int {
        let amount = pendingSpendAnimation
        pendingSpendAnimation = 0
        return amount
    }

    /// End a level's paid session (call on completion). A future fresh start of the
    /// same level charges again. No-op for relaxed/unknown levels.
    func endPaidSession(levelID: String) {
        guard openPaidLevels.remove(levelID) != nil else { return }
        persist()
    }

    /// Reset to a full bar and drop all open paid sessions. Called by Reset Progress.
    func reset() {
        storedEnergy = Self.maxEnergy
        anchor = Date()
        openPaidLevels = []
        pendingSpendAnimation = 0
        persist()
    }

    /// Grant energy (rewarded ad refill, gifts). Clamped to max. No-op for premium.
    func addEnergy(_ amount: Int) {
        guard !unlimited, amount > 0 else { return }
        _ = refresh()
        if storedEnergy >= Self.maxEnergy { anchor = Date() }
        storedEnergy = min(Self.maxEnergy, storedEnergy + amount)
        persist()
    }

    private func persist() {
        defaults.set(storedEnergy, forKey: energyKey)
        defaults.set(anchor.timeIntervalSince1970, forKey: anchorKey)
        defaults.set(Array(openPaidLevels), forKey: openLevelsKey)
    }
}
