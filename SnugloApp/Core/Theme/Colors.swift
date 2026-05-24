import SwiftUI

/// Spec §7 color palette — tek doğruluk kaynağı. Hiçbir View hardcoded hex kullanmaz.
enum AppColors {
    // MARK: - Background / Surface
    static let background   = Color(hex: "#E37B7B")  // brand coral
    static let surface      = Color(hex: "#F5F0E8")  // light warm white

    // MARK: - Grid
    static let gridBackground = Color(hex: "#EAE0D2") // cream board
    static let gridLines      = Color(hex: "#D5C7B5") // grid cell borders

    // MARK: - Block colors
    static let blockPurple  = Color(hex: "#A78BC9")
    static let blockBlue    = Color(hex: "#7B9DC2")
    static let blockCoral   = Color(hex: "#D08585")
    static let blockOrange  = Color(hex: "#E0A865")
    static let blockGreen   = Color(hex: "#9CC290")
    static let blockLilac   = Color(hex: "#C8AAD9")
    // Aliases used in BLOCKER spec
    static let blockPink    = Color(hex: "#C8AAD9")  // == lilac
    static let blockTeal    = Color(hex: "#7B9DC2")  // == blue

    // MARK: - Text
    static let textPrimary   = Color(hex: "#2A2520")
    static let textSecondary = Color(hex: "#7A6F66")

    // MARK: - Semantic
    static let primary    = Color(hex: "#E37B7B")  // == background/coral
    static let accent     = Color(hex: "#A78BC9")  // purple
    static let success    = Color(hex: "#7CA572")
    static let error      = Color(hex: "#C9554E")  // invalid placement red
    static let invalidRed = Color(hex: "#C9554E")  // explicit alias

    // MARK: - Block color palette (index-stable)
    static let blockPalette: [Color] = [
        blockPurple, blockBlue, blockOrange,
        blockGreen, blockCoral, blockLilac
    ]

    /// Deterministic color assignment per piece ID.
    static func blockColor(for pieceID: String) -> Color {
        blockPalette[abs(pieceID.hashValue) % blockPalette.count]
    }
}

// MARK: - Hex initializer
private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
