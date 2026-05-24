// Spacing.swift — Snuglo spec §7 aralık & yarıçap sistemi
import CoreGraphics

public enum SnugloSpacing {

    // MARK: - Temel birim: 4dp
    public static let unit: CGFloat = 4

    // MARK: - Ortak aralıklar
    public static let xs: CGFloat =  4   // 1× birim
    public static let sm: CGFloat =  8   // 2× birim
    public static let md: CGFloat = 16   // 4× birim
    public static let lg: CGFloat = 24   // 6× birim — grid kenar boşluğu
    public static let xl: CGFloat = 32   // 8× birim

    // MARK: - Köşe yarıçapları (spec §7)
    public static let cardRadius:   CGFloat = 16
    public static let buttonRadius: CGFloat = 12
    public static let blockRadius:  CGFloat =  8
    public static let cellRadius:   CGFloat =  4
}
