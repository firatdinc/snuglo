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
    @discardableResult
    func startGameIfAffordable() -> Bool {
        if unlimited { return true }
        _ = refresh()
        guard storedEnergy >= Self.costPerGame else { return false }
        // Leaving "full" → start the regen clock from now.
        if storedEnergy >= Self.maxEnergy { anchor = Date() }
        storedEnergy -= Self.costPerGame
        persist()
        return true
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
    }
}
