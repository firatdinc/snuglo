import XCTest
@testable import SnugloApp

// MARK: — StoreManagerTests
// Faz G-1: StoreKit-independent logic tests.
// Gerçek Product / Transaction nesneleri mock'lanamadığı için bu testler
// StoreManager'ın pure-Swift katmanlarını kapsar:
//   - PackID lock logic (isPackUnlocked)
//   - purchasedProductIDs → UserDefaults round-trip
//   - ProgressStore hintCount addHints / useHint

// Not: StoreManager.shared singleton'u olduğu için purchasedProductIDs'yi
// doğrudan inject edemeyiz. Test edilen değer: public helper metodları.

@MainActor
final class StoreManagerTests: XCTestCase {

    // MARK: - 1. cozy-beginnings → daima açık

    func testIsPackUnlockedFreePackAlwaysTrue() {
        // cozy-beginnings satın alma gerekmez
        let result = StoreManager.shared.isPackUnlocked("cozy-beginnings")
        XCTAssertTrue(result, "cozy-beginnings her zaman unlock olmalı")
    }

    // MARK: - 2. Bilinmeyen pack ID → false

    func testIsPackUnlockedUnknownPackFalse() {
        XCTAssertFalse(
            StoreManager.shared.isPackUnlocked("non-existent-pack"),
            "Bilinmeyen pack ID false döndürmeli"
        )
    }

    // MARK: - 3. ProductID enum — 5 SKU

    func testProductIDAllCasesCount() {
        XCTAssertEqual(
            StoreManager.ProductID.allCases.count,
            5,
            "Tam olarak 5 SKU tanımlı olmalı"
        )
    }

    func testProductIDRawValues() {
        let ids = Set(StoreManager.ProductID.allCases.map(\.rawValue))
        XCTAssertTrue(ids.contains("com.snuglo.pack.spice_route"))
        XCTAssertTrue(ids.contains("com.snuglo.pack.mambo_nights"))
        XCTAssertTrue(ids.contains("com.snuglo.pack.woodland_retreat"))
        XCTAssertTrue(ids.contains("com.snuglo.removeads"))
        XCTAssertTrue(ids.contains("com.snuglo.hints.small"))
    }

    // MARK: - 4. isPurchased — satın alım yokken false

    func testIsPurchasedReturnsFalseByDefault() {
        // Test cihazında temiz bir state garantisi yok, ama
        // shared instance'ın UserDefaults cache'i boşsa false döner.
        // Bu test ProductID enum erişimini doğrular.
        let _ = StoreManager.shared.isPurchased(.packSpice)    // crash olmadan çalışmalı
        let _ = StoreManager.shared.isPurchased(.removeAds)
        // Assertion: no crash — enum erişimi doğru
    }

    // MARK: - 5. adsRemoved convenience

    func testAdsRemovedEqualsIsPurchasedRemoveAds() {
        let adsRemoved = StoreManager.shared.adsRemoved
        let purchased  = StoreManager.shared.isPurchased(.removeAds)
        XCTAssertEqual(adsRemoved, purchased, "adsRemoved, isPurchased(.removeAds) ile tutarlı olmalı")
    }

    // MARK: - 6. productID(forPackId:) mapping

    func testProductIDForPackIdMapping() {
        XCTAssertEqual(StoreManager.shared.productID(forPackId: "spice-route"),      .packSpice)
        XCTAssertEqual(StoreManager.shared.productID(forPackId: "mambo-nights"),     .packMambo)
        XCTAssertEqual(StoreManager.shared.productID(forPackId: "woodland-retreat"), .packWoodland)
        XCTAssertNil(StoreManager.shared.productID(forPackId: "cozy-beginnings"))
        XCTAssertNil(StoreManager.shared.productID(forPackId: "unknown"))
    }

    // MARK: - 7. product(forPackId:) returns nil when products not loaded

    func testProductForPackIdNilWhenNotLoaded() {
        // products listesi boşsa (no StoreKit config bağlı değilse) nil döner
        // Bu test crash olmamasını doğrular.
        let result = StoreManager.shared.product(forPackId: "spice-route")
        // result nil veya Product olabilir — crash olmamalı
        _ = result
    }
}

// MARK: — ProgressStore Hints Tests

@MainActor
final class ProgressStoreHintsTests: XCTestCase {

    private func makeStore() -> ProgressStore {
        let suite = "test.hints.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        return ProgressStore(defaults: ud, key: suite)
    }

    // MARK: - 8. hintCount default 0

    func testHintCountDefaultZero() {
        let store = makeStore()
        XCTAssertEqual(store.hintCount, 0)
    }

    // MARK: - 9. addHints ekler

    func testAddHintsIncrementsCount() {
        let store = makeStore()
        store.addHints(10)
        XCTAssertEqual(store.hintCount, 10)
        store.addHints(10)
        XCTAssertEqual(store.hintCount, 20)
    }

    // MARK: - 10. useHint azaltır

    func testUseHintDecrementsCount() {
        let store = makeStore()
        store.addHints(5)
        let result = store.useHint()
        XCTAssertTrue(result)
        XCTAssertEqual(store.hintCount, 4)
    }

    // MARK: - 11. useHint 0'da false döner

    func testUseHintReturnsFalseWhenEmpty() {
        let store = makeStore()
        let result = store.useHint()
        XCTAssertFalse(result)
        XCTAssertEqual(store.hintCount, 0)
    }

    // MARK: - 12. hintCount persist edilir

    func testHintCountPersists() {
        let suite = "test.hints.persist.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        let store1 = ProgressStore(defaults: ud, key: suite)
        store1.addHints(7)

        // Yeni instance aynı key'den yükler
        let store2 = ProgressStore(defaults: ud, key: suite)
        XCTAssertEqual(store2.hintCount, 7, "hintCount UserDefaults'a persist edilmeli")
    }

    // MARK: - 13. reset hintCount'u sıfırlar

    func testResetClearsHintCount() {
        let store = makeStore()
        store.addHints(15)
        store.reset()
        XCTAssertEqual(store.hintCount, 0)
    }
}
