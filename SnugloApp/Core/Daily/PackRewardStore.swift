import Foundation
import Observation

// MARK: — PackRewardStore
// Grants a one-time celebration reward when the player completes EVERY level in
// a pack. Self-contained (own UserDefaults). Detection marks a pending pack;
// the reward is only banked on collect, so a kill between detect and collect
// can't swallow it. Mirrors the level-up / streak-milestone pending pattern.

@Observable
final class PackRewardStore {

    static let shared = PackRewardStore()

    /// Packs whose completion reward has already been banked.
    private(set) var rewardedPacks: Set<String>
    /// A pack finished but not yet celebrated/collected (drives the overlay).
    private(set) var pendingCompletedPack: String?

    private let defaults: UserDefaults
    private let rewardedKey = "snuglo.packrewards.v1"
    private let pendingKey  = "snuglo.packrewards.pending"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rewardedPacks = Set(defaults.stringArray(forKey: rewardedKey) ?? [])
        pendingCompletedPack = defaults.string(forKey: pendingKey)
    }

    /// Reward for finishing a pack — generous, since it's a rare milestone.
    static let reward: (coins: Int, gems: Int) = (200, 25)

    /// Call after each solve. Flags the pack as pending if it just became fully
    /// complete and hasn't been rewarded yet.
    func checkCompletion(packId: String, totalLevels: Int, completed: Int) {
        guard totalLevels > 0,
              completed >= totalLevels,
              !rewardedPacks.contains(packId),
              pendingCompletedPack == nil else { return }
        pendingCompletedPack = packId
        defaults.set(packId, forKey: pendingKey)
    }

    /// Bank the reward for the pending pack and clear it.
    @MainActor
    func collect(wallet: WalletStore = .shared) {
        guard let pack = pendingCompletedPack else { return }
        wallet.earn(.coin, amount: Self.reward.coins)
        wallet.earn(.gem, amount: Self.reward.gems)
        rewardedPacks.insert(pack)
        defaults.set(Array(rewardedPacks), forKey: rewardedKey)
        pendingCompletedPack = nil
        defaults.removeObject(forKey: pendingKey)
    }
}
