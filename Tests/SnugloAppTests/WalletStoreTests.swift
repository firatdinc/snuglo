import Testing
import Foundation
@testable import SnugloApp

@MainActor
struct WalletStoreTests {

    private func makeStore() -> WalletStore {
        let suiteName = "WalletStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return WalletStore(defaults: defaults, key: "wallet.test")
    }

    // MARK: — earn

    @Test func earn_positiveAmount_increases() {
        let store = makeStore()
        store.earn(.coin, amount: 50)
        #expect(store.coin == 50)
    }

    @Test func earn_zeroAmount_noChange() {
        let store = makeStore()
        store.earn(.coin, amount: 0)
        #expect(store.coin == 0)
    }

    @Test func earn_negativeAmount_noChange() {
        let store = makeStore()
        store.earn(.coin, amount: -10)
        #expect(store.coin == 0)
    }

    @Test func earn_allCurrencies() {
        let store = makeStore()
        store.earn(.coin, amount: 10)
        store.earn(.gem, amount: 2)
        store.earn(.ticket, amount: 1)
        store.earn(.cup, amount: 5)
        #expect(store.coin == 10)
        #expect(store.gem == 2)
        #expect(store.ticket == 1)
        #expect(store.cup == 5)
    }

    // MARK: — spend

    @Test func spend_sufficient_returnsTrue() {
        let store = makeStore()
        store.earn(.gem, amount: 10)
        let result = store.spend(.gem, amount: 3)
        #expect(result == true)
        #expect(store.gem == 7)
    }

    @Test func spend_insufficient_returnsFalse() {
        let store = makeStore()
        store.earn(.coin, amount: 5)
        let result = store.spend(.coin, amount: 10)
        #expect(result == false)
        #expect(store.coin == 5)  // unchanged
    }

    @Test func spend_cup_alwaysFails() {
        let store = makeStore()
        store.earn(.cup, amount: 100)
        let result = store.spend(.cup, amount: 1)
        #expect(result == false)
        #expect(store.cup == 100)  // unchanged
    }

    @Test func spend_zeroAmount_returnsFalse() {
        let store = makeStore()
        store.earn(.coin, amount: 50)
        let result = store.spend(.coin, amount: 0)
        #expect(result == false)
    }

    // MARK: — canAfford

    @Test func canAfford_sufficientBalance_true() {
        let store = makeStore()
        store.earn(.ticket, amount: 3)
        #expect(store.canAfford(.ticket, amount: 2) == true)
    }

    @Test func canAfford_insufficientBalance_false() {
        let store = makeStore()
        store.earn(.ticket, amount: 1)
        #expect(store.canAfford(.ticket, amount: 2) == false)
    }

    @Test func canAfford_cup_alwaysFalse() {
        let store = makeStore()
        store.earn(.cup, amount: 999)
        #expect(store.canAfford(.cup, amount: 1) == false)
    }

    @Test func canAfford_zeroAmount_false() {
        let store = makeStore()
        store.earn(.coin, amount: 100)
        #expect(store.canAfford(.coin, amount: 0) == false)
    }

    // MARK: — exchange

    @Test func exchange_coinToGem_correctRate() {
        let store = makeStore()
        store.earn(.coin, amount: 300)
        let result = store.exchange(from: .coin, to: .gem, amount: 2)
        #expect(result == true)
        #expect(store.coin == 100)  // 300 - 2*100
        #expect(store.gem == 2)
    }

    @Test func exchange_coinToGem_insufficient_fails() {
        let store = makeStore()
        store.earn(.coin, amount: 50)
        let result = store.exchange(from: .coin, to: .gem, amount: 1)  // needs 100
        #expect(result == false)
        #expect(store.coin == 50)
        #expect(store.gem == 0)
    }

    @Test func exchange_gemToTicket_correctRate() {
        let store = makeStore()
        store.earn(.gem, amount: 150)
        let result = store.exchange(from: .gem, to: .ticket, amount: 2)
        #expect(result == true)
        #expect(store.gem == 50)   // 150 - 2*50
        #expect(store.ticket == 2)
    }

    @Test func exchange_invalidPair_fails() {
        let store = makeStore()
        store.earn(.coin, amount: 1000)
        let result = store.exchange(from: .coin, to: .ticket, amount: 1)
        #expect(result == false)
    }

    @Test func exchange_cupSource_fails() {
        let store = makeStore()
        store.earn(.cup, amount: 1000)
        let result = store.exchange(from: .cup, to: .coin, amount: 1)
        #expect(result == false)
    }

    @Test func exchange_zeroAmount_fails() {
        let store = makeStore()
        store.earn(.coin, amount: 1000)
        let result = store.exchange(from: .coin, to: .gem, amount: 0)
        #expect(result == false)
    }

    // MARK: — balance(of:)

    @Test func balance_reflectsEarnings() {
        let store = makeStore()
        store.earn(.gem, amount: 7)
        #expect(store.balance(of: .gem) == 7)
    }

    // MARK: — Persistence

    @Test func persistence_roundTrip() {
        let suiteName = "WalletStoreTests.persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let key = "wallet.persist.test"

        let store1 = WalletStore(defaults: defaults, key: key)
        store1.earn(.coin, amount: 120)
        store1.earn(.gem, amount: 3)
        store1.earn(.ticket, amount: 1)
        store1.earn(.cup, amount: 8)

        let store2 = WalletStore(defaults: defaults, key: key)
        #expect(store2.coin == 120)
        #expect(store2.gem == 3)
        #expect(store2.ticket == 1)
        #expect(store2.cup == 8)
    }

    @Test func persistence_missingKeys_defaultsToZero() {
        let suiteName = "WalletStoreTests.empty.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = WalletStore(defaults: defaults, key: "wallet.empty.test")
        #expect(store.coin == 0)
        #expect(store.gem == 0)
        #expect(store.ticket == 0)
        #expect(store.cup == 0)
    }

    // MARK: — reset

    @Test func reset_clearsAll() {
        let store = makeStore()
        store.earn(.coin, amount: 500)
        store.earn(.gem, amount: 10)
        store.reset()
        #expect(store.coin == 0)
        #expect(store.gem == 0)
        #expect(store.ticket == 0)
        #expect(store.cup == 0)
    }
}
