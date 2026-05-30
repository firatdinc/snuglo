import Foundation

// MARK: — DailyRewardCalculator
// Pure, stateless helper. Maps a 1-based cycle day (1..7) to the reward dict.
// Callers pass the player's premium status; premium bonuses stack on top of the free base.

struct DailyRewardCalculator {

    static func reward(forDay day: Int, isPremium: Bool) -> [Currency: Int] {
        let (freeBase, premiumBonus) = table(day)
        guard isPremium else { return freeBase }
        var result = freeBase
        for (currency, amount) in premiumBonus {
            result[currency, default: 0] += amount
        }
        return result
    }

    // MARK: — Reward table

    private static func table(_ day: Int) -> (free: [Currency: Int], bonus: [Currency: Int]) {
        switch day {
        case 1: return ([.coin: 50], [.coin: 25])
        case 2: return ([.coin: 100], [.coin: 50])
        case 3: return ([.gem: 1], [.gem: 1])
        case 4: return ([.coin: 100], [.coin: 50])
        case 5: return ([.gem: 2], [.gem: 1])
        case 6: return ([.coin: 200], [.coin: 100])
        case 7: return ([.gem: 5, .cup: 1], [.gem: 2])
        default: return ([.coin: 50], [:])
        }
    }
}
