import Testing
import Foundation
@testable import SnugloApp

// MARK: — AchievementsStoreTests
// 4 tests: evaluate unlock+reward, idempotency, persistence round-trip.

@MainActor
struct AchievementsStoreTests {

    private func makeStores() -> (AchievementsStore, WalletStore) {
        let suite = "test.achievements.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        let achievements = AchievementsStore(defaults: ud, key: "\(suite).achievements")
        let wallet       = WalletStore(defaults: ud, key: "\(suite).wallet")
        return (achievements, wallet)
    }

    private func statsWithFirstLevel() -> AchievementStats {
        AchievementStats(
            completedLevels: 1,
            currentStreak: 0,
            perfectSolves: 0,
            hintFreeSolves: 0,
            fastestSolveSeconds: nil
        )
    }

    // MARK: — Evaluate unlocks and grants reward

    @Test func evaluate_unlocksAchievementAndGrantsReward() {
        let (store, wallet) = makeStores()
        let newlyUnlocked = store.evaluate(stats: statsWithFirstLevel(), wallet: wallet)
        #expect(newlyUnlocked.contains(.firstSteps))
        #expect(store.isUnlocked(.firstSteps))
        #expect(wallet.balance(of: .coin) >= 50)
    }

    // MARK: — Evaluate is idempotent

    @Test func evaluate_idempotent_noDoubleReward() {
        let (store, wallet) = makeStores()
        store.evaluate(stats: statsWithFirstLevel(), wallet: wallet)
        let coinAfterFirst = wallet.balance(of: .coin)
        let second = store.evaluate(stats: statsWithFirstLevel(), wallet: wallet)
        #expect(second.isEmpty)
        #expect(wallet.balance(of: .coin) == coinAfterFirst)
    }

    // MARK: — Persistence round-trip

    @Test func persistenceRoundTrip_survivesReload() {
        let suite = "test.achievements.rt.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        let wallet = WalletStore(defaults: ud, key: "\(suite).wallet")
        let store1 = AchievementsStore(defaults: ud, key: "\(suite).achievements")
        store1.evaluate(stats: statsWithFirstLevel(), wallet: wallet)
        #expect(store1.isUnlocked(.firstSteps))

        let store2 = AchievementsStore(defaults: ud, key: "\(suite).achievements")
        #expect(store2.isUnlocked(.firstSteps))
    }

    // MARK: — Reset clears all unlocks

    @Test func reset_clearsUnlocked() {
        let (store, wallet) = makeStores()
        store.evaluate(stats: statsWithFirstLevel(), wallet: wallet)
        #expect(!store.unlocked.isEmpty)
        store.reset()
        #expect(store.unlocked.isEmpty)
    }
}
