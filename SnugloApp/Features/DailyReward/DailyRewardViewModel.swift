import Foundation
import Observation

// MARK: — DailyRewardViewModel

@Observable
@MainActor
final class DailyRewardViewModel {

    // MARK: — State

    private(set) var canClaim: Bool = false
    private(set) var currentDay: Int = 1
    private(set) var lastClaimedReward: [Currency: Int]?
    var showBanner: Bool = false

    // MARK: — DI

    private let progress: ProgressStore
    private let store: StoreManager
    private let wallet: WalletStore
    private let achievements: AchievementsStore

    // MARK: — Init

    init(
        progress: ProgressStore = .shared,
        store: StoreManager = .shared,
        wallet: WalletStore = .shared,
        achievements: AchievementsStore = .shared
    ) {
        self.progress = progress
        self.store = store
        self.wallet = wallet
        self.achievements = achievements
        refresh()
    }

    // MARK: — Actions

    func refresh() {
        canClaim = progress.canClaimDailyReward
        currentDay = (progress.lastClaimedDay % 7) + 1
    }

    func claim() {
        guard canClaim else { return }
        guard let reward = progress.claimDailyReward(isPremium: store.adsRemoved, wallet: wallet) else { return }
        lastClaimedReward = reward
        showBanner = true
        refresh()
        let stats = AchievementStats(from: progress)
        achievements.evaluate(stats: stats, wallet: wallet)
        scheduleBannerDismiss()
    }

    private func scheduleBannerDismiss() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self.showBanner = false
        }
    }
}
