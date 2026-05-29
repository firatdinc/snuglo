import Testing
@testable import SnugloApp

struct CurrencyRewardTests {

    // MARK: — Coin formula

    @Test func oneStar_coin_is10() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 90, previousBestSeconds: nil)
        #expect(reward[.coin] == 10)
    }

    @Test func twoStar_coin_is20() {
        let reward = CurrencyReward.forLevelComplete(stars: 2, elapsedSeconds: 90, previousBestSeconds: nil)
        #expect(reward[.coin] == 20)
    }

    @Test func threeStar_coin_is30() {
        let reward = CurrencyReward.forLevelComplete(stars: 3, elapsedSeconds: 90, previousBestSeconds: nil)
        #expect(reward[.coin] == 30)
    }

    @Test func zeroStar_coin_is0_noEntry() {
        let reward = CurrencyReward.forLevelComplete(stars: 0, elapsedSeconds: 90, previousBestSeconds: 100)
        #expect(reward[.coin] == nil)
    }

    @Test func speedBonus_under60s_adds5() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 59, previousBestSeconds: 100)
        #expect(reward[.coin] == 15)  // 10 + 5
    }

    @Test func speedBonus_exactly60s_noBonus() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 60, previousBestSeconds: 100)
        #expect(reward[.coin] == 10)
    }

    @Test func speedBonus_over60s_noBonus() {
        let reward = CurrencyReward.forLevelComplete(stars: 2, elapsedSeconds: 120, previousBestSeconds: 200)
        #expect(reward[.coin] == 20)
    }

    // MARK: — Gem formula

    @Test func firstCompletion_nilPrevBest_gemsPersonalBest() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 90, previousBestSeconds: nil)
        // isPersonalBest=true (first time), stars≠3 → 1 gem
        #expect(reward[.gem] == 1)
    }

    @Test func fasterThanBest_gemBestBonus() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 50, previousBestSeconds: 100)
        #expect(reward[.gem] == 1)
    }

    @Test func slowerThanBest_noGemBestBonus() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 200, previousBestSeconds: 100)
        #expect(reward[.gem] == nil)
    }

    @Test func threeStar_gemStarBonus() {
        let reward = CurrencyReward.forLevelComplete(stars: 3, elapsedSeconds: 200, previousBestSeconds: 100)
        // not faster → gemBest=0, stars==3 → gemStar=1
        #expect(reward[.gem] == 1)
    }

    @Test func threeStar_andPersonalBest_twoGems() {
        let reward = CurrencyReward.forLevelComplete(stars: 3, elapsedSeconds: 50, previousBestSeconds: 100)
        // gemBest=1 + gemStar=1 = 2
        #expect(reward[.gem] == 2)
    }

    @Test func threeStar_firstCompletion_twoGems() {
        let reward = CurrencyReward.forLevelComplete(stars: 3, elapsedSeconds: 90, previousBestSeconds: nil)
        // isPersonalBest=true + stars==3 → 2 gems
        #expect(reward[.gem] == 2)
    }

    @Test func noGem_noEntry() {
        let reward = CurrencyReward.forLevelComplete(stars: 1, elapsedSeconds: 200, previousBestSeconds: 100)
        #expect(reward[.gem] == nil)
    }

    // MARK: — Boundary: speed bonus + 3-star + personal best

    @Test func maxReward_speedPlus3StarPlusBest() {
        let reward = CurrencyReward.forLevelComplete(stars: 3, elapsedSeconds: 45, previousBestSeconds: 60)
        #expect(reward[.coin] == 35)  // 30 + 5
        #expect(reward[.gem] == 2)    // gemBest=1 + gemStar=1
    }

    // MARK: — Cup and ticket never appear in reward

    @Test func reward_noCupOrTicket() {
        let reward = CurrencyReward.forLevelComplete(stars: 3, elapsedSeconds: 45, previousBestSeconds: nil)
        #expect(reward[.cup] == nil)
        #expect(reward[.ticket] == nil)
    }
}
