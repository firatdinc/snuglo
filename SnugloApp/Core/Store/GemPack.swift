import Foundation

// MARK: — GemPack
// Consumable gem bundles sold via RevenueCat / StoreKit. Product IDs must match
// App Store Connect (and the RevenueCat dashboard). Amounts/prices are the launch
// ladder — tune with analytics.

struct GemPack: Identifiable, Hashable {
    let id: String          // == productID
    var productID: String { id }
    let gems: Int
    let fallbackPrice: String   // shown while StoreKit prices load
    let bestValue: Bool

    static let catalog: [GemPack] = [
        GemPack(id: "com.snuglo.gems.tier1", gems: 100, fallbackPrice: "$0.99", bestValue: false),
        GemPack(id: "com.snuglo.gems.tier2", gems: 550, fallbackPrice: "$4.99", bestValue: false),
        GemPack(id: "com.snuglo.gems.tier3", gems: 1200, fallbackPrice: "$9.99", bestValue: false),
        GemPack(id: "com.snuglo.gems.tier4", gems: 2600, fallbackPrice: "$19.99", bestValue: true),
        GemPack(id: "com.snuglo.gems.tier5", gems: 7000, fallbackPrice: "$49.99", bestValue: false)
    ]
}
