import Foundation
import Observation

@Observable
@MainActor
final class WalletStore {

    static let shared = WalletStore()

    private(set) var coin: Int = 0
    private(set) var gem: Int = 0
    private(set) var ticket: Int = 0
    private(set) var cup: Int = 0

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "snuglo.wallet.v1") {
        self.defaults = defaults
        self.key = key
        load()
    }

    // MARK: — Read

    func balance(of currency: Currency) -> Int {
        switch currency {
        case .coin:   return coin
        case .gem:    return gem
        case .ticket: return ticket
        case .cup:    return cup
        }
    }

    func canAfford(_ currency: Currency, amount: Int) -> Bool {
        guard currency.isSpendable, amount > 0 else { return false }
        return balance(of: currency) >= amount
    }

    // MARK: — Write

    func earn(_ currency: Currency, amount: Int) {
        guard amount > 0 else { return }
        switch currency {
        case .coin:   coin   += amount
        case .gem:    gem    += amount
        case .ticket: ticket += amount
        case .cup:    cup    += amount
        }
        save()
    }

    @discardableResult
    func spend(_ currency: Currency, amount: Int) -> Bool {
        guard currency.isSpendable, amount > 0, balance(of: currency) >= amount else { return false }
        switch currency {
        case .coin:   coin   -= amount
        case .gem:    gem    -= amount
        case .ticket: ticket -= amount
        case .cup:    return false  // unreachable: isSpendable guard above
        }
        save()
        return true
    }

    /// `amount` is in TARGET currency.
    /// exchange(from: .coin, to: .gem, amount: 1) costs 100 coins, grants 1 gem.
    @discardableResult
    func exchange(from source: Currency, to target: Currency, amount: Int) -> Bool {
        guard amount > 0 else { return false }
        switch (source, target) {
        case (.coin, .gem):
            let cost = amount * CurrencyRate.coinPerGem
            guard spend(.coin, amount: cost) else { return false }
            earn(.gem, amount: amount)
            return true
        case (.gem, .ticket):
            let cost = amount * CurrencyRate.gemPerTicket
            guard spend(.gem, amount: cost) else { return false }
            earn(.ticket, amount: amount)
            return true
        default:
            return false
        }
    }

    func reset() {
        coin = 0; gem = 0; ticket = 0; cup = 0
        save()
    }

    // MARK: — Persistence

    private struct Snapshot: Codable {
        var coin: Int
        var gem: Int
        var ticket: Int
        var cup: Int

        init(coin: Int, gem: Int, ticket: Int, cup: Int) {
            self.coin = coin; self.gem = gem; self.ticket = ticket; self.cup = cup
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            coin   = try container.decodeIfPresent(Int.self, forKey: .coin)   ?? 0
            gem    = try container.decodeIfPresent(Int.self, forKey: .gem)    ?? 0
            ticket = try container.decodeIfPresent(Int.self, forKey: .ticket) ?? 0
            cup    = try container.decodeIfPresent(Int.self, forKey: .cup)    ?? 0
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        coin = snap.coin; gem = snap.gem; ticket = snap.ticket; cup = snap.cup
    }

    private func save() {
        let snap = Snapshot(coin: coin, gem: gem, ticket: ticket, cup: cup)
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
        }
    }
}
