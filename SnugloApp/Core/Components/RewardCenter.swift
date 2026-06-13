import SwiftUI
import Observation

// MARK: — RewardCenter
// Global trigger for the centred animated reward popup. Any code can call
// `RewardCenter.shared.showCurrency(...)` / `.showEnergy(...)` and the host
// overlay in RootView presents an animated "+N" celebration.

@Observable
@MainActor
final class RewardCenter {

    static let shared = RewardCenter()

    struct Reward: Identifiable, Equatable {
        let id = UUID()
        var systemImage: String        // SF Symbol fallback (e.g. energy bolt)
        var assetName: String?         // custom illustrated icon (currencies)
        var amount: Int
        var tint: Color
    }

    var pending: Reward?

    private init() {}

    func showCurrency(_ currency: Currency, amount: Int) {
        guard amount > 0 else { return }
        pending = Reward(systemImage: currency.sfSymbol, assetName: currency.assetName,
                         amount: amount, tint: currency.tint)
    }

    func showEnergy(_ amount: Int) {
        guard amount > 0 else { return }
        pending = Reward(systemImage: "bolt.fill", assetName: nil,
                         amount: amount, tint: AppColors.tertiary)
    }

    func dismiss() { pending = nil }
}
