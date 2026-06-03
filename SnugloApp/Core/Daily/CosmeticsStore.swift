import Foundation
import Observation

// MARK: — CosmeticsStore
// Tracks cosmetics unlocked with gems (block skins). Skins are usable when EITHER
// the player reaches the unlock level OR buys them here. Self-contained (own key).

@Observable
final class CosmeticsStore {

    static let shared = CosmeticsStore()

    private(set) var unlockedSkins: Set<String>

    private let defaults: UserDefaults
    private let key = "snuglo.cosmetics.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        unlockedSkins = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func isSkinUnlocked(_ id: String) -> Bool { unlockedSkins.contains(id) }

    /// Gem price for a skin, derived from its unlock level.
    static func skinCost(unlockLevel: Int) -> Int { max(5, unlockLevel * 2) }

    @MainActor
    @discardableResult
    func buySkin(_ id: String, costGems: Int, wallet: WalletStore = .shared) -> Bool {
        if unlockedSkins.contains(id) { return true }
        guard wallet.spend(.gem, amount: costGems) else { return false }
        unlockedSkins.insert(id)
        defaults.set(Array(unlockedSkins), forKey: key)
        return true
    }
}
