import SwiftUI

// MARK: — NookCatalog
// Static content for the cozy meta-layer ("Snuglo Nook"): decor you buy with
// coins/gems, scene backgrounds (gem sink), and the mascots you "rescue" by
// completing campaign packs. Single source of truth — NookStore owns ownership
// state, this file owns the catalog. All names are localization keys (nook.*).

enum NookCatalog {

    // MARK: — Decor (placed in the Nook; soft coin sink + a few premium gem items)

    struct Decor: Identifiable, Hashable {
        let id: String
        let symbol: String       // SF Symbol (iOS 18 safe)
        let nameKey: String
        let cost: Int
        let currency: Currency   // .coin (soft) or .gem (hard)
        let tint: Color          // AppColors token only
        /// Where this prop sits inside the Nook canvas — normalized (0…1, top-left
        /// origin). Royal-Match-style fixed slots: tap the empty spot, watch the
        /// piece pop into place. Curated back→front so the arrangement layers
        /// naturally (props with larger y draw on top).
        let anchor: CGPoint
        /// Base point size of the prop symbol; the cushion behind scales from it.
        let slotSize: CGFloat
    }

    static let decor: [Decor] = [
        // Coin (soft) — the everyday "fill your nook" loop
        Decor(id: "tea", symbol: "cup.and.saucer.fill", nameKey: "nook.decor.tea", cost: 25, currency: .coin, tint: AppColors.blockBlush, anchor: CGPoint(x: 0.88, y: 0.70), slotSize: 26),
        Decor(id: "plant", symbol: "leaf.fill", nameKey: "nook.decor.plant", cost: 30, currency: .coin, tint: AppColors.blockSage, anchor: CGPoint(x: 0.11, y: 0.71), slotSize: 36),
        Decor(id: "photo", symbol: "photo.fill", nameKey: "nook.decor.photo", cost: 35, currency: .coin, tint: AppColors.blockPeach, anchor: CGPoint(x: 0.20, y: 0.50), slotSize: 28),
        Decor(id: "lamp", symbol: "lamp.table.fill", nameKey: "nook.decor.lamp", cost: 40, currency: .coin, tint: AppColors.blockCream, anchor: CGPoint(x: 0.31, y: 0.66), slotSize: 34),
        Decor(id: "clock", symbol: "clock.fill", nameKey: "nook.decor.clock", cost: 50, currency: .coin, tint: AppColors.blockCream, anchor: CGPoint(x: 0.39, y: 0.49), slotSize: 28),
        Decor(id: "books", symbol: "books.vertical.fill", nameKey: "nook.decor.books", cost: 60, currency: .coin, tint: AppColors.blockPeach, anchor: CGPoint(x: 0.62, y: 0.50), slotSize: 32),
        Decor(id: "teddy", symbol: "teddybear.fill", nameKey: "nook.decor.teddy", cost: 70, currency: .coin, tint: AppColors.blockBlush, anchor: CGPoint(x: 0.85, y: 0.87), slotSize: 34),
        Decor(id: "fish", symbol: "fish.fill", nameKey: "nook.decor.fish", cost: 80, currency: .coin, tint: AppColors.blockSage, anchor: CGPoint(x: 0.71, y: 0.68), slotSize: 30),
        Decor(id: "guitar", symbol: "guitars.fill", nameKey: "nook.decor.guitar", cost: 90, currency: .coin, tint: AppColors.blockLavender, anchor: CGPoint(x: 0.83, y: 0.52), slotSize: 36),
        Decor(id: "console", symbol: "gamecontroller.fill", nameKey: "nook.decor.console", cost: 100, currency: .coin, tint: AppColors.blockLavender, anchor: CGPoint(x: 0.68, y: 0.86), slotSize: 36),
        Decor(id: "sofa", symbol: "sofa.fill", nameKey: "nook.decor.sofa", cost: 120, currency: .coin, tint: AppColors.blockPeach, anchor: CGPoint(x: 0.22, y: 0.87), slotSize: 52),
        Decor(id: "bed", symbol: "bed.double.fill", nameKey: "nook.decor.bed", cost: 140, currency: .coin, tint: AppColors.blockLavender, anchor: CGPoint(x: 0.48, y: 0.88), slotSize: 52),
        // Gem (hard) — premium cozy flourishes
        Decor(id: "fairylights", symbol: "sparkles", nameKey: "nook.decor.fairylights", cost: 15, currency: .gem, tint: AppColors.tertiary, anchor: CGPoint(x: 0.50, y: 0.11), slotSize: 34),
        Decor(id: "starlight", symbol: "moon.stars.fill", nameKey: "nook.decor.starlight", cost: 20, currency: .gem, tint: AppColors.blockLavender, anchor: CGPoint(x: 0.84, y: 0.14), slotSize: 30),
        Decor(id: "fireplace", symbol: "flame.fill", nameKey: "nook.decor.fireplace", cost: 30, currency: .gem, tint: AppColors.primary, anchor: CGPoint(x: 0.50, y: 0.70), slotSize: 40),
        Decor(id: "royal", symbol: "crown.fill", nameKey: "nook.decor.royal", cost: 35, currency: .gem, tint: AppColors.tertiary, anchor: CGPoint(x: 0.16, y: 0.14), slotSize: 30)
    ]

    static func decor(id: String) -> Decor? { decor.first { $0.id == id } }

    // MARK: — Scenes (Nook background; first is free, rest are a gem sink)

    struct Scene: Identifiable, Hashable {
        let id: String           // asset name in Assets.xcassets (scene-*)
        let nameKey: String
        let cost: Int            // gems; 0 = free
    }

    static let freeScene = "scene-island"

    static let scenes: [Scene] = [
        Scene(id: "scene-island", nameKey: "nook.scene.island", cost: 0),
        Scene(id: "scene-forest", nameKey: "nook.scene.forest", cost: 20),
        Scene(id: "scene-flower", nameKey: "nook.scene.flower", cost: 20),
        Scene(id: "scene-beach", nameKey: "nook.scene.beach", cost: 20),
        Scene(id: "scene-mushroom", nameKey: "nook.scene.mushroom", cost: 25),
        Scene(id: "scene-lake", nameKey: "nook.scene.lake", cost: 25),
        Scene(id: "scene-autumn", nameKey: "nook.scene.autumn", cost: 25),
        Scene(id: "scene-desert", nameKey: "nook.scene.desert", cost: 25),
        Scene(id: "scene-waterfall", nameKey: "nook.scene.waterfall", cost: 30),
        Scene(id: "scene-snow", nameKey: "nook.scene.snow", cost: 30),
        Scene(id: "scene-volcano", nameKey: "nook.scene.volcano", cost: 35)
    ]

    static func scene(id: String) -> Scene? { scenes.first { $0.id == id } }

    // MARK: — Mascots (rescued for free by completing campaign packs)

    struct Mascot: Identifiable, Hashable {
        let id: String           // == packId
        let asset: String        // mascot artwork (Assets)
        var packId: String { id }
        /// The pack whose completion rescues this friend — its localized title
        /// doubles as the friend's "home" label (no extra per-mascot strings).
        var homeTitleKey: String { "pack.\(id.replacingOccurrences(of: "-", with: "_")).title" }
    }

    /// One mascot per campaign pack, art taken from the shared PackArt table so a
    /// pack's animal and its Nook friend always match.
    static var mascots: [Mascot] {
        MockData.allPacks.map { pack in
            Mascot(id: pack.id, asset: PackArt.theme(forPackId: pack.id).art)
        }
    }
}
