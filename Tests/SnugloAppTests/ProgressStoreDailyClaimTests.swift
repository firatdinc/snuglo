import Testing
import Foundation
@testable import SnugloApp

// MARK: — ProgressStoreDailyClaimTests
// 4 tests: canClaim / claim / idempotency / cycle-reset.

@MainActor
struct ProgressStoreDailyClaimTests {

    private func makeStores() -> (ProgressStore, WalletStore) {
        let suite = "test.dailyclaim.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        let progress = ProgressStore(defaults: ud, key: "\(suite).progress")
        let wallet   = WalletStore(defaults: ud, key: "\(suite).wallet")
        return (progress, wallet)
    }

    // MARK: — Can claim initially

    @Test func canClaimDailyReward_initiallyTrue() {
        let (store, _) = makeStores()
        #expect(store.canClaimDailyReward == true)
    }

    // MARK: — Claimed same day → cannot re-claim

    @Test func cannotClaimTwiceOnSameDay() {
        let (store, wallet) = makeStores()
        let result = store.claimDailyReward(now: .now, isPremium: false, wallet: wallet)
        #expect(result != nil)
        #expect(store.canClaimDailyReward == false)
        let second = store.claimDailyReward(now: .now, isPremium: false, wallet: wallet)
        #expect(second == nil)
    }

    // MARK: — Claim on a different day → can claim again

    @Test func canClaimOnDifferentDay() {
        let (store, wallet) = makeStores()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        store.claimDailyReward(now: yesterday, isPremium: false, wallet: wallet)
        #expect(store.canClaimDailyReward == true)
    }

    // MARK: — Gap > 1 day resets cycle to day 1

    @Test func gapResetsCycleToDayOne() {
        let (store, wallet) = makeStores()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        // Simulate having previously claimed day 5
        store.claimDailyReward(now: threeDaysAgo, isPremium: false, wallet: wallet)
        // Claim again today — cycle should have reset
        let reward = store.claimDailyReward(now: .now, isPremium: false, wallet: wallet)
        #expect(reward != nil)
        #expect(store.lastClaimedDay == 1)
    }
}
