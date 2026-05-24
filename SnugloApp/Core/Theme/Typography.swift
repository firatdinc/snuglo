// Typography.swift — Snuglo spec §7 tipografi sistemi
import SwiftUI

public enum SnugloTypography {

    // MARK: - Ölçek (pt)
    public static let titleSize:    CGFloat = 24
    public static let subtitleSize: CGFloat = 17
    public static let bodySize:     CGFloat = 15
    public static let captionSize:  CGFloat = 12

    // MARK: - Font factory'leri

    /// Başlıklar — SF Rounded semi-bold
    public static func title() -> Font {
        .system(size: titleSize, weight: .semibold, design: .rounded)
    }

    /// Alt başlıklar — SF Rounded medium
    public static func subtitle() -> Font {
        .system(size: subtitleSize, weight: .medium, design: .rounded)
    }

    /// Gövde metni — SF Pro regular
    public static func body() -> Font {
        .system(size: bodySize, weight: .regular)
    }

    /// Açıklama metni
    public static func caption() -> Font {
        .system(size: captionSize, weight: .regular)
    }

    /// Sayılar (zamanlayıcı, blok boyutları) — SF Mono medium
    public static func mono(size: CGFloat = bodySize) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// Blok içi hücre sayısı etiketi
    public static func blockNumber() -> Font {
        .system(size: captionSize, weight: .semibold, design: .rounded)
    }
}
