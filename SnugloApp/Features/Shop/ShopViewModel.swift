import Foundation
import Observation

@Observable
@MainActor
final class ShopViewModel {

    // MARK: — Daily Deal

    private(set) var currentDeal: DailyDeal
    private(set) var showClaimedBanner: Bool = false
    private(set) var claimedCurrency: Currency?
    private(set) var claimedAmount: Int = 0
    /// false → the banner shows an "insufficient / ad not ready" warning instead
    /// of a reward confirmation.
    private(set) var claimSucceeded: Bool = true

    // MARK: — Exchange

    var coinToGemAmount: Int = 1
    var gemToTicketAmount: Int = 1

    /// Details of the most recent successful exchange — drives the sign banner.
    struct ExchangeReceipt: Equatable {
        var fromCurrency: Currency
        var cost: Int
        var toCurrency: Currency
        var reward: Int
    }

    private(set) var showExchangeBanner: Bool = false
    private(set) var exchangeInsufficient: Currency?
    private(set) var lastExchange: ExchangeReceipt?

    // MARK: — Private

    private let wallet: WalletStore

    // MARK: — Init

    init(
        date: Date = Date(),
        offers: [DailyDeal] = DailyDeal.allDeals,
        wallet: WalletStore = .shared
    ) {
        self.wallet = wallet
        currentDeal = DailyDealRotator.deal(forDate: date, offers: offers) ?? offers[0]
    }

    // MARK: — Computed

    var canExchangeCoinToGem: Bool {
        wallet.canAfford(.coin, amount: coinToGemAmount * CurrencyRate.coinPerGem)
    }

    var canExchangeGemToTicket: Bool {
        wallet.canAfford(.gem, amount: gemToTicketAmount * CurrencyRate.gemPerTicket)
    }

    // MARK: — Actions

    /// Claim the daily deal: watch ad or spend currency based on the deal action.
    func claimDeal() {
        switch currentDeal.action {
        case .watchAd(let earn, let amount):
            guard AdsManager.shared.rewardedAvailable else { flashInsufficient(nil); return }
            AdsManager.shared.showRewarded { [weak self] in
                Task { @MainActor in self?.grantClaim(earn, amount: amount) }
            }
        case .spend(let from, let cost, let earn, let amount):
            guard wallet.spend(from, amount: cost) else { flashInsufficient(from); return }
            grantClaim(earn, amount: amount)
        }
    }

    /// Watch a rewarded ad to earn a currency pack reward (with confirmation banner).
    func watchAdForPack(_ pack: CurrencyPack) {
        guard AdsManager.shared.rewardedAvailable else { flashInsufficient(nil); return }
        AdsManager.shared.showRewarded { [weak self] in
            Task { @MainActor in self?.grantClaim(pack.earn, amount: pack.amount) }
        }
    }

    /// Credit a reward and surface the success confirmation banner.
    private func grantClaim(_ currency: Currency, amount: Int) {
        wallet.earn(currency, amount: amount)
        claimedCurrency = currency
        claimedAmount = amount
        claimSucceeded = true
        showClaimedBanner = true
    }

    /// Surface a warning banner: not enough currency (`currency`) or no ad ready (nil).
    private func flashInsufficient(_ currency: Currency?) {
        claimedCurrency = currency
        claimSucceeded = false
        showClaimedBanner = true
    }

    func exchangeCoinToGem() {
        let success = wallet.exchange(from: .coin, to: .gem, amount: coinToGemAmount)
        exchangeInsufficient = success ? nil : .coin
        lastExchange = success
            ? ExchangeReceipt(fromCurrency: .coin,
                              cost: coinToGemAmount * CurrencyRate.coinPerGem,
                              toCurrency: .gem,
                              reward: coinToGemAmount)
            : nil
        showExchangeBanner = true
    }

    func exchangeGemToTicket() {
        let success = wallet.exchange(from: .gem, to: .ticket, amount: gemToTicketAmount)
        exchangeInsufficient = success ? nil : .gem
        lastExchange = success
            ? ExchangeReceipt(fromCurrency: .gem,
                              cost: gemToTicketAmount * CurrencyRate.gemPerTicket,
                              toCurrency: .ticket,
                              reward: gemToTicketAmount)
            : nil
        showExchangeBanner = true
    }

    func dismissBanner() { showClaimedBanner = false }

    func dismissExchangeBanner() { showExchangeBanner = false }
}
