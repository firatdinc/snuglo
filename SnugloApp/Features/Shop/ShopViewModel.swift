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

    // MARK: — Exchange

    var coinToGemAmount: Int = 1
    var gemToTicketAmount: Int = 1

    private(set) var showExchangeBanner: Bool = false
    private(set) var exchangeInsufficient: Currency?

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
            AdsManager.shared.showRewarded { [weak self] in
                Task { @MainActor in
                    self?.wallet.earn(earn, amount: amount)
                    self?.claimedCurrency = earn
                    self?.claimedAmount = amount
                    self?.showClaimedBanner = true
                }
            }
        case .spend(let from, let cost, let earn, let amount):
            guard wallet.spend(from, amount: cost) else { return }
            wallet.earn(earn, amount: amount)
            claimedCurrency = earn
            claimedAmount = amount
            showClaimedBanner = true
        }
    }

    /// Watch a rewarded ad to earn a currency pack reward.
    func watchAdForPack(_ pack: CurrencyPack) {
        AdsManager.shared.showRewarded { [weak self] in
            Task { @MainActor in
                self?.wallet.earn(pack.earn, amount: pack.amount)
            }
        }
    }

    func exchangeCoinToGem() {
        let success = wallet.exchange(from: .coin, to: .gem, amount: coinToGemAmount)
        exchangeInsufficient = success ? nil : .coin
        showExchangeBanner = true
    }

    func exchangeGemToTicket() {
        let success = wallet.exchange(from: .gem, to: .ticket, amount: gemToTicketAmount)
        exchangeInsufficient = success ? nil : .gem
        showExchangeBanner = true
    }

    func dismissBanner() { showClaimedBanner = false }

    func dismissExchangeBanner() { showExchangeBanner = false }
}
