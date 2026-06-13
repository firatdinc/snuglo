import StoreKit
import SwiftUI
import Observation

// Disambiguation: SwiftUI also defines a `Transaction` type (for animations).
// Use StoreKit.Transaction explicitly throughout this file.
private typealias SKTransaction = StoreKit.Transaction

// MARK: — StoreManager
// StoreKit 2 IAP yönetimi — Faz G-1.
//
// 5 SKU:
//   Non-Consumable: spice_route ($2.99), mambo_nights ($3.99),
//                   woodland_retreat ($4.99), removeads ($4.99)
//   Consumable:     hints.small (+10 hints, $0.99)
//
// UserDefaults: purchased IDs cache (non-consumable'lar için; consumable count
// ProgressStore'da tutulur).

@Observable
final class StoreManager {

    // MARK: - Singleton

    static let shared = StoreManager()

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case packSpice      = "com.snuglo.pack.spice_route"
        case packMambo      = "com.snuglo.pack.mambo_nights"
        case packWoodland   = "com.snuglo.pack.woodland_retreat"
        case removeAds      = "com.snuglo.removeads"
        case hintsSmall     = "com.snuglo.hints.small"
        /// Premium: unlimited energy + no ads. Auto-renewable subscription
        /// (RevenueCat will manage purchase; entitlement still resolves here via
        /// StoreKit currentEntitlements).
        case premium        = "com.snuglo.premium"
    }

    // MARK: - Observed State

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading: Bool = false
    var lastError: String?

    // MARK: - Private

    private var transactionListener: Task<Void, Never>?
    private let udKey = "snuglo.purchased.v1"

    // MARK: - Init / Deinit

    private init() {
        loadPurchasedIDsFromUserDefaults()
        transactionListener = Task.detached { [weak self] in
            // Transaction.updates dinle (refund, revoke, external purchase)
            for await result in SKTransaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public API

    /// App başlarken / ShopView görünürken çağrılır.
    func loadProducts() async {
        guard products.isEmpty else {
            await refreshEntitlements()
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                // Fiyata göre sırala (önce ucuz)
                .sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            lastError = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    /// Bir ürün satın al. Başarılı → true, iptal/hata → false.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handle(transactionResult: VerificationResult<StoreKit.Transaction>.verified(transaction))
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Restore Purchases — AppStore.sync() + entitlement refresh.
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
        } catch {
            lastError = "Geri yükleme başarısız: \(error.localizedDescription)"
        }
        await refreshEntitlements()
    }

    // MARK: - Query Helpers

    func isPurchased(_ id: ProductID) -> Bool {
        purchasedProductIDs.contains(id.rawValue)
    }

    /// Pack unlock durumu. Yeni monetizasyon modelinde (enerji + Premium) tüm
    /// pack'ler ücretsiz; erişim level-level PROGRESYON ile açılır (pack-başı IAP
    /// kaldırıldı). Premium da her şeyi açar.
    func isPackUnlocked(_ packId: String) -> Bool { true }

    /// Reklam kaldırma — AdMob buradan okur. Premium da reklamsızdır. Remove-Ads
    /// artık RevenueCat üzerinden satılıyor; RC entitlement'ı bir flag'e mirror'lanır.
    var adsRemoved: Bool {
        isPurchased(.removeAds)
        || UserDefaults.standard.bool(forKey: "snuglo.ads.removed")
        || isPremium
    }

    /// Premium: unlimited energy + ads removed. Driven by the premium
    /// subscription entitlement (RevenueCat / StoreKit). A DEBUG override allows
    /// testing the premium path without a sandbox purchase.
    var isPremium: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "snuglo.debug.premium") { return true }
        #endif
        // RevenueCat entitlement (mirrored to a flag to avoid cross-actor reads)
        // OR a direct StoreKit premium purchase.
        return isPurchased(.premium) || UserDefaults.standard.bool(forKey: "snuglo.premium.active")
    }

    /// Bir product ID için görünen fiyatı döndür (ör. "$2.99").
    func displayPrice(for id: ProductID) -> String? {
        products.first(where: { $0.id == id.rawValue })?.displayPrice
    }

    /// ID'ye göre Product nesnesini bul.
    func product(for id: ProductID) -> Product? {
        products.first(where: { $0.id == id.rawValue })
    }

    // MARK: - Internal: Transaction Handling

    private func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async {
        do {
            let tx = try checkVerified(transactionResult)
            if tx.revocationDate == nil {
                // Satın alım geçerli
                if tx.productType == Product.ProductType.consumable {
                    // Consumable → ProgressStore'a ekle, ID'yi kaydetme
                    if tx.productID == ProductID.hintsSmall.rawValue {
                        await MainActor.run {
                            ProgressStore.shared.addHints(10)
                        }
                    }
                } else {
                    purchasedProductIDs.insert(tx.productID)
                    saveToUserDefaults()
                }
            } else {
                // Revoke (refund)
                purchasedProductIDs.remove(tx.productID)
                saveToUserDefaults()
            }
            await tx.finish()
        } catch {
            // Unverified transaction — güvenlik gereği yoksay
        }
    }

    private func refreshEntitlements() async {
        var set = Set<String>()
        for await result in SKTransaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.revocationDate == nil,
               tx.productType != .consumable {
                set.insert(tx.productID)
            }
        }
        purchasedProductIDs = set
        saveToUserDefaults()
    }

    private func checkVerified<T: Sendable>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let error): throw error
        }
    }

    // MARK: - Persistence (non-consumable cache)

    private func loadPurchasedIDsFromUserDefaults() {
        let arr = UserDefaults.standard.stringArray(forKey: udKey) ?? []
        purchasedProductIDs = Set(arr)
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(Array(purchasedProductIDs), forKey: udKey)
    }
}

// MARK: - Convenience: pack Product lookup

extension StoreManager {

    /// Pack ID'sine karşılık gelen ProductID (varsa).
    func productID(forPackId packId: String) -> ProductID? {
        switch packId {
        case "spice-route":      return .packSpice
        case "mambo-nights":     return .packMambo
        case "woodland-retreat": return .packWoodland
        default:                 return nil
        }
    }

    /// Pack ID'sine karşılık gelen Product (StoreKit) nesnesi.
    func product(forPackId packId: String) -> Product? {
        guard let pid = productID(forPackId: packId) else { return nil }
        return product(for: pid)
    }
}
