import Foundation

enum CurrencyReward {
    /// Pure reward formula for level completion.
    /// coin = stars×5 + (elapsed<60 ? 3 : 0)   (tightened to push paid coin packs)
    /// gem  = (isPersonalBest ? 1 : 0) + (stars==3 ? 1 : 0)
    static func forLevelComplete(
        stars: Int,
        elapsedSeconds: Int,
        previousBestSeconds: Int?
    ) -> [Currency: Int] {
        var reward: [Currency: Int] = [:]

        let coinBase = max(0, stars) * 5
        let speedBonus = elapsedSeconds < 60 ? 3 : 0
        let totalCoin = coinBase + speedBonus
        if totalCoin > 0 { reward[.coin] = totalCoin }

        let isPersonalBest: Bool
        if let prevBest = previousBestSeconds {
            isPersonalBest = elapsedSeconds < prevBest
        } else {
            isPersonalBest = true  // first completion always counts
        }
        let gemBest = isPersonalBest ? 1 : 0
        let gemStar = stars == 3 ? 1 : 0
        let totalGem = gemBest + gemStar
        if totalGem > 0 { reward[.gem] = totalGem }

        return reward
    }
}
