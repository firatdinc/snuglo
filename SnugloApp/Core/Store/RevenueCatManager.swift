import Foundation
import StoreKit
import SwiftUI

// MARK: — RevenueCatManager
// Thin wrapper around RevenueCat. Source of truth for the Premium entitlement
// (unlimited energy + no ads) and the seller for consumable gem packs. Gated on
// `canImport(RevenueCat)` so the project still compiles before the SPM package
// resolves; the stub keeps call-sites alive.

#if canImport(RevenueCat)
import RevenueCat

@MainActor
@Observable
final class RevenueCatManager {

    static let shared = RevenueCatManager()

    /// Entitlement identifier configured on the RevenueCat dashboard.
    static let premiumEntitlementID = "premium"
    /// Premium subscription product id (matches StoreManager.ProductID.premium).
    static let premiumProductID = "com.snuglo.premium"

    /// Active Premium entitlement → unlimited energy + no ads.
    private(set) var hasPremium: Bool = false
    private(set) var products: [String: StoreProduct] = [:]
    var lastError: String?
    var isPurchasing: Bool = false

    @ObservationIgnored private var listener: Task<Void, Never>?

    private init() {}

    // MARK: - Configure

    static func configure(apiKey: String) {
        #if DEBUG
        Purchases.logLevel = .info
        #else
        Purchases.logLevel = .error
        #endif
        Purchases.configure(withAPIKey: apiKey)
        Task { @MainActor in shared.listener = shared.startListening() }
        Task { await shared.refreshCustomerInfo() }
        Task { await shared.loadProducts() }
    }

    private func startListening() -> Task<Void, Never> {
        Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(customerInfo: info)
            }
        }
    }

    private func apply(customerInfo info: CustomerInfo) {
        hasPremium = info.entitlements[Self.premiumEntitlementID]?.isActive == true
        // Mirror to a plain flag so non-MainActor StoreManager.isPremium can read
        // it without crossing actors (and so it survives relaunch until refresh).
        UserDefaults.standard.set(hasPremium, forKey: "snuglo.premium.active")
    }

    func refreshCustomerInfo() async {
        if let info = try? await Purchases.shared.customerInfo() { apply(customerInfo: info) }
    }

    // MARK: - Products

    func loadProducts() async {
        let ids = Set(GemPack.catalog.map(\.productID) + [Self.premiumProductID])
        let fetched = await Purchases.shared.products(Array(ids))
        var map: [String: StoreProduct] = [:]
        for p in fetched { map[p.productIdentifier] = p }
        products = map
    }

    func displayPrice(for pack: GemPack) -> String {
        products[pack.productID]?.localizedPriceString ?? pack.fallbackPrice
    }

    var premiumPrice: String { products[Self.premiumProductID]?.localizedPriceString ?? "$4.99" }

    // MARK: - Purchase

    /// Buy a gem pack; on success the gems are credited to the wallet.
    @discardableResult
    func purchase(_ pack: GemPack) async -> Bool {
        guard let product = products[pack.productID] else { lastError = "Product unavailable"; return false }
        isPurchasing = true; defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled { return false }
            WalletStore.shared.earn(.gem, amount: pack.gems)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Buy / subscribe to Premium. Entitlement listener flips `hasPremium`.
    @discardableResult
    func purchasePremium() async -> Bool {
        guard let product = products[Self.premiumProductID] else { lastError = "Product unavailable"; return false }
        isPurchasing = true; defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled { return false }
            apply(customerInfo: result.customerInfo)
            return hasPremium
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        if let info = try? await Purchases.shared.restorePurchases() { apply(customerInfo: info) }
    }
}

#else
// MARK: - SDK-absent stub (keeps the project compiling before SPM resolves).

@MainActor
@Observable
final class RevenueCatManager {
    static let shared = RevenueCatManager()
    static let premiumEntitlementID = "premium"
    static let premiumProductID = "com.snuglo.premium"

    private(set) var hasPremium: Bool = false
    var lastError: String?
    var isPurchasing: Bool = false

    private init() {}

    static func configure(apiKey: String) {}
    func refreshCustomerInfo() async {}
    func loadProducts() async {}
    func displayPrice(for pack: GemPack) -> String { pack.fallbackPrice }
    var premiumPrice: String { "$4.99" }
    @discardableResult func purchase(_ pack: GemPack) async -> Bool { false }
    @discardableResult func purchasePremium() async -> Bool { false }
    func restorePurchases() async {}
}
#endif
