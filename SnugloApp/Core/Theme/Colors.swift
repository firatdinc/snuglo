import SwiftUI

// MARK: — Nordic Hearth Design System: Colors
// Source: Designs/INDEX.md (imported 2026-05-25)
// Block palette: derived from INDEX.md "soft pastels — lavender/sage/peach/blush/cream/dusty olive"
//   Hex values are hand-tuned to match desaturated Nordic warmth; 6 distinct pastels.
// Light theme only. Dark mode: TODO Faz H — see BLOCKERS.md [BLOCKER-06].
// No View should use hard-coded hex values; always reference AppColors.

/// Canonical color tokens for the Nordic Hearth design system.
enum AppColors {

    // MARK: — Background / Surface (tonal layering L0 → L4)

    /// L0 — page background, warm off-white paper
    static let background               = Color(hex: "#FDF8FB")
    /// L1 — lowest-elevation containers
    static let surfaceContainerLow      = Color(hex: "#F8F2F5")
    /// L2 — standard containers (cards, tray)
    static let surfaceContainer         = Color(hex: "#F2ECF0")
    /// L3 — elevated containers
    static let surfaceContainerHigh     = Color(hex: "#ECE7EA")
    /// L4 — highest-elevation containers
    static let surfaceContainerHighest  = Color(hex: "#E6E1E4")

    // MARK: — Primary (Lavender / CTA)

    static let primary          = Color(hex: "#65587A")
    static let primaryContainer = Color(hex: "#C5B5DC")
    static let onPrimary        = Color(hex: "#FFFFFF")

    // MARK: — Secondary (Cocoa)

    static let secondary   = Color(hex: "#675C58")
    static let onSecondary = Color(hex: "#FFFFFF")

    // MARK: — Tertiary (Warm Olive)

    static let tertiary   = Color(hex: "#665F31")
    static let onTertiary = Color(hex: "#FFFFFF")

    // MARK: — Text / Content

    /// Deep cocoa — primary text, NEVER pure black
    static let onSurface        = Color(hex: "#1C1B1D")
    /// Muted secondary text
    static let onSurfaceVariant = Color(hex: "#49454D")
    /// Body copy — warm dark brown, NEVER pure black (Designs/INDEX.md)
    static let bodyText         = Color(hex: "#3A332D")

    // MARK: — Outline

    static let outline        = Color(hex: "#7A757E")
    static let outlineVariant = Color(hex: "#CBC4CE")

    // MARK: — Error

    static let error   = Color(hex: "#BA1A1A")
    static let onError = Color(hex: "#FFFFFF")

    // MARK: — Block fills (6 pastels — Nordic Hearth palette)

    static let blockLavender   = Color(hex: "#C5B5DC") // = primaryContainer
    static let blockSage       = Color(hex: "#B5CDBA") // warm sage green
    static let blockPeach      = Color(hex: "#EDCDB8") // soft peach / apricot
    static let blockBlush      = Color(hex: "#E8BAC8") // rose blush
    static let blockCream      = Color(hex: "#E8DFC5") // warm cream
    static let blockDustyOlive = Color(hex: "#C5CAA8") // dusty olive

    /// Index-stable palette — DO NOT reorder (deterministic piece coloring).
    static let blockPalette: [Color] = [
        blockLavender, blockSage, blockPeach,
        blockBlush, blockCream, blockDustyOlive
    ]

    // MARK: — Elevation / Shadow

    /// Base tonal shadow color — rgba(58, 51, 45).
    /// Apply `.opacity(0.06)` for L1 (idle), `.opacity(0.12)` for picked-up state.
    static let shadowAmbient = Color(red: 58 / 255, green: 51 / 255, blue: 45 / 255)

    // MARK: — Semantic aliases

    static let invalidRed = error      // invalid placement feedback
    static let success    = primary    // solved state indicator

    // MARK: — GridView aliases

    static let gridBackground = surfaceContainerLow
    static let gridLines      = outlineVariant

    // MARK: — Helpers

    /// Deterministic, index-stable block color for a piece, keyed by piece ID.
    /// Uses FNV-1a (32-bit) — result is identical across every process launch.
    /// `String.hashValue` is randomised per-process (Swift SE-0206 / SE-0143) and
    /// MUST NOT be used for anything that requires cross-run consistency.
    static func blockColor(for pieceID: String) -> Color {
        var h: UInt32 = 2166136261  // FNV-1a 32-bit offset basis
        for b in pieceID.utf8 {
            h ^= UInt32(b)
            h &*= 16777619           // FNV-1a 32-bit prime (wrapping multiply)
        }
        return blockPalette[Int(h % UInt32(blockPalette.count))]
    }
}

// MARK: — Private hex initializer

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
