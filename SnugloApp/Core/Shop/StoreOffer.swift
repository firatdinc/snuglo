import Foundation

// MARK: — DealAction

enum DealAction {
    /// Watch a rewarded ad → earn currency.
    case watchAd(earn: Currency, amount: Int)
    /// Spend `cost` units of `from` currency → earn `amount` units of `to` currency.
    case spend(from: Currency, cost: Int, earn: Currency, amount: Int)
}

// MARK: — DailyDeal

struct DailyDeal: Identifiable {
    let id: String
    let titleKey: String
    let messageKey: String
    let sfSymbol: String
    let action: DealAction
}

extension DailyDeal {
    /// Five hardcoded daily deals, rotated via DailyDealRotator.
    static let allDeals: [DailyDeal] = [
        DailyDeal(
            id: "deal_gems_ad",
            titleKey: "shop.deal.gems.title",
            messageKey: "shop.deal.gems.message",
            sfSymbol: "diamond.fill",
            action: .watchAd(earn: .gem, amount: 20)
        ),
        DailyDeal(
            id: "deal_coins_ad",
            titleKey: "shop.deal.coins.title",
            messageKey: "shop.deal.coins.message",
            sfSymbol: "circle.circle.fill",
            action: .watchAd(earn: .coin, amount: 150)
        ),
        DailyDeal(
            id: "deal_gems_coins",
            titleKey: "shop.deal.exchange.title",
            messageKey: "shop.deal.exchange.message",
            sfSymbol: "arrow.left.arrow.right",
            action: .spend(from: .coin, cost: 300, earn: .gem, amount: 5)
        ),
        DailyDeal(
            id: "deal_ticket_gems",
            titleKey: "shop.deal.ticket.gems.title",
            messageKey: "shop.deal.ticket.gems.message",
            sfSymbol: "tag.fill",
            action: .spend(from: .gem, cost: 80, earn: .ticket, amount: 2)
        )
    ]
}

// MARK: — CurrencyPack

struct CurrencyPack: Identifiable {
    let id: String
    let titleKey: String
    let sfSymbol: String
    let earn: Currency
    let amount: Int
}

extension CurrencyPack {
    /// Four ad-reward currency packs shown in the coin packs grid.
    static let allPacks: [CurrencyPack] = [
        CurrencyPack(id: "cp_coins_sm", titleKey: "shop.pack.coins.sm", sfSymbol: "circle.circle.fill", earn: .coin, amount: 50),
        CurrencyPack(id: "cp_coins_md", titleKey: "shop.pack.coins.md", sfSymbol: "circle.circle.fill", earn: .coin, amount: 150),
        CurrencyPack(id: "cp_gems_sm", titleKey: "shop.pack.gems.sm", sfSymbol: "diamond.fill", earn: .gem, amount: 10)
    ]
}
