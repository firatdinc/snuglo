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

    /// Remove-Ads non-consumable → entitlement + product id (ASC/RC).
    static let removeAdsEntitlementID = "ads_removed"
    static let removeAdsProductID     = "com.snuglo.removeads"
    /// Hints consumable (grants 10 hints per purchase).
    static let hintsProductID    = "com.snuglo.hints.small"
    static let hintsPerPurchase  = 10
    /// Keys consumable (grants 3 chest keys per purchase).
    static let keysProductID     = "com.snuglo.keys.small"
    static let keysPerPurchase   = 3

    /// Active Premium entitlement → unlimited energy + no ads.
    private(set) var hasPremium: Bool = false
    /// Active Remove-Ads entitlement (Premium also removes ads).
    private(set) var hasRemoveAds: Bool = false
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
        let removeAds = info.entitlements[Self.removeAdsEntitlementID]?.isActive == true
        hasRemoveAds = removeAds || hasPremium
        // Mirror to plain flags so non-MainActor StoreManager can read them without
        // crossing actors (and so they survive relaunch until refresh).
        UserDefaults.standard.set(hasPremium, forKey: "snuglo.premium.active")
        UserDefaults.standard.set(hasRemoveAds, forKey: "snuglo.ads.removed")
    }

    func refreshCustomerInfo() async {
        if let info = try? await Purchases.shared.customerInfo() { apply(customerInfo: info) }
    }

    // MARK: - Products

    func loadProducts() async {
        let ids = Set(GemPack.catalog.map(\.productID)
                      + [Self.premiumProductID, Self.removeAdsProductID, Self.hintsProductID, Self.keysProductID])
        let fetched = await Purchases.shared.products(Array(ids))
        var map: [String: StoreProduct] = [:]
        for p in fetched { map[p.productIdentifier] = p }
        products = map
    }

    func displayPrice(for pack: GemPack) -> String {
        products[pack.productID]?.localizedPriceString ?? pack.fallbackPrice
    }

    var premiumPrice: String { products[Self.premiumProductID]?.localizedPriceString ?? "$4.99" }
    var removeAdsPrice: String { products[Self.removeAdsProductID]?.localizedPriceString ?? "$2.99" }
    var hintsPrice: String { products[Self.hintsProductID]?.localizedPriceString ?? "$0.99" }
    var keysPrice: String { products[Self.keysProductID]?.localizedPriceString ?? "$0.99" }

    // MARK: - Purchase

    /// Buy a gem pack; on success the gems are credited to the wallet.
    @discardableResult
    func purchase(_ pack: GemPack) async -> Bool {
        guard let product = products[pack.productID] else { lastError = NSLocalizedString("shop.error.productUnavailable", comment: ""); return false }
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
        guard let product = products[Self.premiumProductID] else { lastError = NSLocalizedString("shop.error.productUnavailable", comment: ""); return false }
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

    /// Buy Remove-Ads (non-consumable). Entitlement listener flips `hasRemoveAds`.
    @discardableResult
    func purchaseRemoveAds() async -> Bool {
        guard let product = products[Self.removeAdsProductID] else { lastError = NSLocalizedString("shop.error.productUnavailable", comment: ""); return false }
        isPurchasing = true; defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled { return false }
            apply(customerInfo: result.customerInfo)
            return hasRemoveAds
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Buy a hints pack (consumable). On success credits `hintsPerPurchase` hints.
    @discardableResult
    func purchaseHints() async -> Bool {
        guard let product = products[Self.hintsProductID] else { lastError = NSLocalizedString("shop.error.productUnavailable", comment: ""); return false }
        isPurchasing = true; defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled { return false }
            ProgressStore.shared.addHints(Self.hintsPerPurchase)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Buy a keys pack (consumable). On success credits `keysPerPurchase` chest keys.
    @discardableResult
    func purchaseKeys() async -> Bool {
        guard let product = products[Self.keysProductID] else { lastError = NSLocalizedString("shop.error.productUnavailable", comment: ""); return false }
        isPurchasing = true; defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled { return false }
            ChestStore.shared.addKey(Self.keysPerPurchase)
            return true
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
    static let removeAdsEntitlementID = "ads_removed"
    static let removeAdsProductID     = "com.snuglo.removeads"
    static let hintsProductID    = "com.snuglo.hints.small"
    static let hintsPerPurchase  = 10
    static let keysProductID     = "com.snuglo.keys.small"
    static let keysPerPurchase   = 3

    private(set) var hasPremium: Bool = false
    private(set) var hasRemoveAds: Bool = false
    var lastError: String?
    var isPurchasing: Bool = false

    private init() {}

    static func configure(apiKey: String) {}
    func refreshCustomerInfo() async {}
    func loadProducts() async {}
    func displayPrice(for pack: GemPack) -> String { pack.fallbackPrice }
    var premiumPrice: String { "$4.99" }
    var removeAdsPrice: String { "$2.99" }
    var hintsPrice: String { "$0.99" }
    var keysPrice: String { "$0.99" }
    @discardableResult func purchase(_ pack: GemPack) async -> Bool { false }
    @discardableResult func purchasePremium() async -> Bool { false }
    @discardableResult func purchaseRemoveAds() async -> Bool { false }
    @discardableResult func purchaseHints() async -> Bool { false }
    @discardableResult func purchaseKeys() async -> Bool { false }
    func restorePurchases() async {}
}
#endif
