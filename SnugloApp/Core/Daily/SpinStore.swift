import Foundation
import Observation

// MARK: — SpinStore
// Once-per-day spin wheel — a classic daily-return hook (variable reward +
// anticipation). Self-contained: own UserDefaults key, grants via WalletStore.

@Observable
final class SpinStore {

    static let shared = SpinStore()

    /// Wheel segments (currency, amount), clockwise from the top.
    // Tickets are NOT a free faucet — they come only from spending gems
    // (Shop → exchange / gem deal). The wheel pays coins + the occasional gem.
    static let segments: [(currency: Currency, amount: Int)] = [
        (.coin, 50), (.coin, 150), (.gem, 1), (.coin, 100),
        (.coin, 500), (.coin, 80), (.gem, 2), (.coin, 120),
    ]
    /// Selection weights (sum 100) — jackpot/gems rarer than small coins.
    static let weights: [Int] = [22, 14, 8, 18, 3, 20, 5, 10]

    private(set) var lastSpinDay: Int

    private let defaults: UserDefaults
    private let key = "snuglo.spin.v1"
    private struct P: Codable { var lastSpinDay: Int }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let d = defaults.data(forKey: key), let p = try? JSONDecoder().decode(P.self, from: d) {
            lastSpinDay = p.lastSpinDay
        } else {
            lastSpinDay = -1
        }
    }

    var canSpin: Bool { SpinStore.currentDay() != lastSpinDay }

    /// Picks the winning segment index (weighted). Pure — does not grant yet, so
    /// the UI can animate the wheel to this index first.
    func chooseIndex() -> Int {
        let total = SpinStore.weights.reduce(0, +)
        var r = Int.random(in: 0..<total)
        for (i, w) in SpinStore.weights.enumerated() {
            if r < w { return i }
            r -= w
        }
        return SpinStore.weights.count - 1
    }

    /// Grants the reward for `index` and locks spinning until tomorrow.
    @MainActor
    func commit(index: Int, wallet: WalletStore = .shared) {
        guard canSpin else { return }
        let seg = SpinStore.segments[index]
        wallet.earn(seg.currency, amount: seg.amount)
        lastSpinDay = SpinStore.currentDay()
        persist()
    }

    func refresh() { /* day is computed live via canSpin */ }

    private func persist() {
        if let d = try? JSONEncoder().encode(P(lastSpinDay: lastSpinDay)) {
            defaults.set(d, forKey: key)
        }
    }

    private static func currentDay() -> Int { Int(Date().timeIntervalSince1970 / 86_400) }
}
