// Colors.swift — Snuglo spec §7 renk token'ları
import SwiftUI

public enum SnugloColors {

    // MARK: - Brand
    /// Marka ana rengi — arka plan, splash, primary CTA
    public static let coral    = Color(snugloHex: "#E37B7B")

    // MARK: - Board
    /// Grid arka planı
    public static let cream    = Color(snugloHex: "#EAE0D2")
    /// Grid hücre kenarlıkları
    public static let gridLine = Color(snugloHex: "#D5C7B5")

    // MARK: - Block colours
    public static let blockPurple = Color(snugloHex: "#A78BC9")
    public static let blockBlue   = Color(snugloHex: "#7B9DC2")
    public static let blockRed    = Color(snugloHex: "#D08585")
    public static let blockOrange = Color(snugloHex: "#E0A865")
    public static let blockGreen  = Color(snugloHex: "#9CC290")
    public static let blockLilac  = Color(snugloHex: "#C8AAD9")

    // MARK: - Text
    public static let textPrimary   = Color(snugloHex: "#2A2520")
    public static let textSecondary = Color(snugloHex: "#7A6F66")

    // MARK: - Semantic
    public static let success = Color(snugloHex: "#7CA572")
    public static let error   = Color(snugloHex: "#C9554E")

    // MARK: - Ordered palette for piece index → colour mapping
    public static let blockPalette: [Color] = [
        blockPurple, blockBlue, blockRed, blockOrange, blockGreen, blockLilac
    ]

    public static let blockPaletteKeys = ["purple", "blue", "red", "orange", "green", "lilac"]

    /// Semantic renk anahtarı → SwiftUI Color
    public static func block(forKey key: String) -> Color {
        switch key {
        case "purple": return blockPurple
        case "blue":   return blockBlue
        case "red":    return blockRed
        case "orange": return blockOrange
        case "green":  return blockGreen
        case "lilac":  return blockLilac
        default:       return blockPurple
        }
    }
}

// MARK: - Hex initialiser (private)
extension Color {
    init(snugloHex hex: String) {
        let clean = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
