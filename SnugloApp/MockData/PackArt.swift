import Foundation

// MARK: — PackArt
// Single source of truth for each pack's themed artwork. Every surface (Levels
// card icon, PackDetail title icon, PackDetail hero scene) reads from here so a
// pack's animal/icon and its scene stay thematically matched (e.g. owl → woodland,
// cactus → desert). Cycled by the pack's position in MockData.allPacks.

enum PackArt {

    struct Theme {
        let art: String     // small illustrated icon (Assets) — animal/object
        let scene: String   // full hero scene (Assets)
    }

    /// Ordered themes; each pairs an icon with a fitting scene.
    static let themes: [Theme] = [
        Theme(art: "mascot-sloth", scene: "scene-island"),    // cozy start
        Theme(art: "fox", scene: "scene-forest"),    // forest fox
        Theme(art: "owl", scene: "scene-mushroom"),  // woodland owl
        Theme(art: "hedgehog", scene: "scene-autumn"),    // autumn hedgehog
        Theme(art: "cow", scene: "scene-flower"),    // meadow cow
        Theme(art: "lion", scene: "scene-desert"),    // savanna lion
        Theme(art: "bee", scene: "scene-waterfall"), // lush bee
        Theme(art: "mascot-hippo", scene: "scene-lake"),      // lake hippo
        Theme(art: "cactus", scene: "scene-desert"),    // desert cactus
        Theme(art: "tomato", scene: "scene-flower"),    // garden tomato
        Theme(art: "mascot-rabbit", scene: "scene-beach"),     // beach rabbit
        Theme(art: "sand", scene: "scene-beach"),     // sandy shore
        Theme(art: "mascot-tiger", scene: "scene-volcano"),   // bold tiger
        Theme(art: "Rabbit", scene: "scene-snow"),      // snowy rabbit
        Theme(art: "Carrot", scene: "scene-lake")      // garden by the lake
    ]

    static func theme(forIndex i: Int) -> Theme {
        guard !themes.isEmpty else { return Theme(art: "mascot-sloth", scene: "scene-island") }
        let n = themes.count
        return themes[((i % n) + n) % n]
    }

    /// Theme for a pack by id (its position in MockData.allPacks).
    static func theme(forPackId id: String) -> Theme {
        let idx = MockData.allPacks.firstIndex { $0.id == id } ?? 0
        return theme(forIndex: idx)
    }
}
