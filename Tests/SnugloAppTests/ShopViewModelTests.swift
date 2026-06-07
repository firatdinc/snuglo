import Testing
import Foundation
@testable import SnugloApp

@MainActor
struct ShopViewModelTests {

    // MARK: — Helpers

    private func makeWallet(coin: Int = 0, gem: Int = 0, ticket: Int = 0) -> WalletStore {
        let store = WalletStore(
            defaults: UserDefaults(suiteName: "ShopVMTests.\(UUID().uuidString)")!,
            key: "shopvm.wallet.test"
        )
        if coin   > 0 { store.earn(.coin, amount: coin) }
        if gem    > 0 { store.earn(.gem, amount: gem) }
        if ticket > 0 { store.earn(.ticket, amount: ticket) }
        return store
    }

    private func makeVM(wallet: WalletStore, date: Date = Date(), deals: [DailyDeal] = DailyDeal.allDeals) -> ShopViewModel {
        ShopViewModel(date: date, offers: deals, wallet: wallet)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return cal.date(from: comps)!
    }

    // MARK: — Init / deal selection

    @Test func init_selectsDealForDate() {
        let date = makeDate(year: 2026, month: 5, day: 30)
        let deals = DailyDeal.allDeals
        let vm = makeVM(wallet: makeWallet(), date: date, deals: deals)
        let expected = DailyDealRotator.deal(forDate: date, offers: deals)
        #expect(vm.currentDeal.id == expected?.id)
    }

    @Test func init_singleDeal_alwaysSelected() {
        let only = [DailyDeal.allDeals[0]]
        let vm = makeVM(wallet: makeWallet(), deals: only)
        #expect(vm.currentDeal.id == only[0].id)
    }

    // MARK: — canExchangeCoinToGem

    @Test func canExchangeCoinToGem_sufficientBalance_returnsTrue() {
        let wallet = makeWallet(coin: 100)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 1
        #expect(vm.canExchangeCoinToGem == true)
    }

    @Test func canExchangeCoinToGem_insufficientBalance_returnsFalse() {
        let wallet = makeWallet(coin: 50)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 1     // requires 100 coins
        #expect(vm.canExchangeCoinToGem == false)
    }

    @Test func canExchangeCoinToGem_multipleUnits_correctCost() {
        let wallet = makeWallet(coin: 350)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 3     // requires 300 coins → affordable
        #expect(vm.canExchangeCoinToGem == true)
        vm.coinToGemAmount = 4     // requires 400 coins → not affordable
        #expect(vm.canExchangeCoinToGem == false)
    }

    // MARK: — canExchangeGemToTicket

    @Test func canExchangeGemToTicket_sufficientBalance_returnsTrue() {
        let wallet = makeWallet(gem: 50)
        let vm = makeVM(wallet: wallet)
        vm.gemToTicketAmount = 1
        #expect(vm.canExchangeGemToTicket == true)
    }

    @Test func canExchangeGemToTicket_insufficientBalance_returnsFalse() {
        let wallet = makeWallet(gem: 30)
        let vm = makeVM(wallet: wallet)
        vm.gemToTicketAmount = 1   // requires 50 gems
        #expect(vm.canExchangeGemToTicket == false)
    }

    // MARK: — exchangeCoinToGem

    @Test func exchangeCoinToGem_deductsCoinAndGrantsGem() {
        let wallet = makeWallet(coin: 200)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 2   // costs 200 coins → grants 2 gems
        vm.exchangeCoinToGem()
        #expect(wallet.coin == 0)
        #expect(wallet.gem  == 2)
    }

    @Test func exchangeCoinToGem_insufficientBalance_noChange() {
        let wallet = makeWallet(coin: 50)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 1
        vm.exchangeCoinToGem()
        #expect(wallet.coin == 50)
        #expect(wallet.gem  == 0)
    }

    // MARK: — exchangeGemToTicket

    @Test func exchangeGemToTicket_deductsGemAndGrantsTicket() {
        let wallet = makeWallet(gem: 100)
        let vm = makeVM(wallet: wallet)
        vm.gemToTicketAmount = 2   // costs 100 gems → grants 2 tickets
        vm.exchangeGemToTicket()
        #expect(wallet.gem    == 0)
        #expect(wallet.ticket == 2)
    }

    @Test func exchangeGemToTicket_insufficientBalance_noChange() {
        let wallet = makeWallet(gem: 20)
        let vm = makeVM(wallet: wallet)
        vm.gemToTicketAmount = 1
        vm.exchangeGemToTicket()
        #expect(wallet.gem    == 20)
        #expect(wallet.ticket == 0)
    }

    // MARK: — Exchange banner

    @Test func exchangeCoinToGem_success_showsBannerNoInsufficient() {
        let wallet = makeWallet(coin: 200)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 2
        vm.exchangeCoinToGem()
        #expect(vm.showExchangeBanner == true)
        #expect(vm.exchangeInsufficient == nil)
    }

    @Test func exchangeCoinToGem_insufficient_showsBannerWithCoinCurrency() {
        let wallet = makeWallet(coin: 50)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 1
        vm.exchangeCoinToGem()
        #expect(vm.showExchangeBanner == true)
        #expect(vm.exchangeInsufficient == .coin)
    }

    // MARK: — claimDeal (spend path)

    @Test func claimDeal_spendPath_sufficientBalance_grantsEarn() {
        let spendDeal = DailyDeal(
            id: "test_spend",
            titleKey: "x", messageKey: "x", sfSymbol: "x",
            action: .spend(from: .coin, cost: 100, earn: .gem, amount: 3)
        )
        let wallet = makeWallet(coin: 100)
        let vm = makeVM(wallet: wallet, deals: [spendDeal])
        vm.claimDeal()
        #expect(wallet.coin == 0)
        #expect(wallet.gem  == 3)
        #expect(vm.showClaimedBanner == true)
        #expect(vm.claimedCurrency == .gem)
        #expect(vm.claimedAmount == 3)
    }

    @Test func claimDeal_spendPath_insufficientBalance_noChange() {
        let spendDeal = DailyDeal(
            id: "test_spend_fail",
            titleKey: "x", messageKey: "x", sfSymbol: "x",
            action: .spend(from: .coin, cost: 500, earn: .gem, amount: 10)
        )
        let wallet = makeWallet(coin: 100)
        let vm = makeVM(wallet: wallet, deals: [spendDeal])
        vm.claimDeal()
        // Wallet is untouched, but an "insufficient" warning banner is now shown.
        #expect(wallet.coin == 100)
        #expect(wallet.gem  == 0)
        #expect(vm.showClaimedBanner == true)
        #expect(vm.claimSucceeded == false)
    }

    // MARK: — dismissBanner

    @Test func dismissBanner_clearsShowClaimedBanner() {
        let spendDeal = DailyDeal(
            id: "test_dismiss",
            titleKey: "x", messageKey: "x", sfSymbol: "x",
            action: .spend(from: .coin, cost: 10, earn: .gem, amount: 1)
        )
        let wallet = makeWallet(coin: 50)
        let vm = makeVM(wallet: wallet, deals: [spendDeal])
        vm.claimDeal()
        #expect(vm.showClaimedBanner == true)
        vm.dismissBanner()
        #expect(vm.showClaimedBanner == false)
    }

    // MARK: — Exchange state-transition (Reviewer IMPORTANT #2)

    @Test func exchangeCoinToGem_success_dismissResetsShowBanner() {
        let wallet = makeWallet(coin: 1000)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 1
        vm.exchangeCoinToGem()
        #expect(vm.showExchangeBanner == true)
        #expect(vm.exchangeInsufficient == nil)
        vm.dismissExchangeBanner()
        #expect(vm.showExchangeBanner == false)
        #expect(vm.exchangeInsufficient == nil)
    }

    @Test func exchangeGemToTicket_insufficient_capturesCurrencyAndDismissesBanner() {
        let wallet = makeWallet(gem: 10)           // needs 50 gem → insufficient
        let vm = makeVM(wallet: wallet)
        vm.gemToTicketAmount = 1
        vm.exchangeGemToTicket()
        #expect(vm.showExchangeBanner == true)
        #expect(vm.exchangeInsufficient == .gem)
        vm.dismissExchangeBanner()
        #expect(vm.showExchangeBanner == false)    // dismiss clears the flag
        // exchangeInsufficient stays .gem until next exchange (by design)
    }

    @Test(.timeLimit(.minutes(1)))
    func exchangeCoinToGem_simulatedAutoDismiss_bannerFalseAfterDelay() async throws {
        // Auto-dismiss runs in ShopView: Task.sleep(2.5 s) then calls dismissExchangeBanner().
        // Here we simulate that same sequence at the VM level.
        let wallet = makeWallet(coin: 100)
        let vm = makeVM(wallet: wallet)
        vm.coinToGemAmount = 1
        vm.exchangeCoinToGem()
        #expect(vm.showExchangeBanner == true)
        try await Task.sleep(nanoseconds: 3_000_000_000)
        vm.dismissExchangeBanner()
        #expect(vm.showExchangeBanner == false)
    }
}
