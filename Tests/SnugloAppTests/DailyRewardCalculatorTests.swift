import Testing
@testable import SnugloApp

// MARK: — DailyRewardCalculatorTests
// 14 tests: 7 days × free + premium paths.

@MainActor
struct DailyRewardCalculatorTests {

    // MARK: — Day 1

    @Test func day1_free() {
        let reward = DailyRewardCalculator.reward(forDay: 1, isPremium: false)
        #expect(reward[.coin] == 50)
        #expect(reward[.gem] == nil)
    }

    @Test func day1_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 1, isPremium: true)
        #expect(reward[.coin] == 75)
    }

    // MARK: — Day 2

    @Test func day2_free() {
        let reward = DailyRewardCalculator.reward(forDay: 2, isPremium: false)
        #expect(reward[.coin] == 100)
    }

    @Test func day2_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 2, isPremium: true)
        #expect(reward[.coin] == 150)
    }

    // MARK: — Day 3

    @Test func day3_free() {
        let reward = DailyRewardCalculator.reward(forDay: 3, isPremium: false)
        #expect(reward[.gem] == 1)
        #expect(reward[.coin] == nil)
    }

    @Test func day3_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 3, isPremium: true)
        #expect(reward[.gem] == 2)
    }

    // MARK: — Day 4

    @Test func day4_free() {
        let reward = DailyRewardCalculator.reward(forDay: 4, isPremium: false)
        #expect(reward[.coin] == 100)
    }

    @Test func day4_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 4, isPremium: true)
        #expect(reward[.coin] == 150)
    }

    // MARK: — Day 5

    @Test func day5_free() {
        let reward = DailyRewardCalculator.reward(forDay: 5, isPremium: false)
        #expect(reward[.gem] == 2)
    }

    @Test func day5_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 5, isPremium: true)
        #expect(reward[.gem] == 3)
    }

    // MARK: — Day 6

    @Test func day6_free() {
        let reward = DailyRewardCalculator.reward(forDay: 6, isPremium: false)
        #expect(reward[.coin] == 200)
    }

    @Test func day6_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 6, isPremium: true)
        #expect(reward[.coin] == 300)
    }

    // MARK: — Day 7

    @Test func day7_free() {
        let reward = DailyRewardCalculator.reward(forDay: 7, isPremium: false)
        #expect(reward[.gem] == 5)
        #expect(reward[.cup] == 1)
    }

    @Test func day7_premium() {
        let reward = DailyRewardCalculator.reward(forDay: 7, isPremium: true)
        #expect(reward[.gem] == 7)
        #expect(reward[.cup] == 1)
    }
}
