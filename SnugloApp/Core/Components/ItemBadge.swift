import SwiftUI

// MARK: — ItemBadge
// Compact card showing 0-3 stars (top row), an SF Symbol icon (centre),
// and an optional integer count badge (bottom-right corner).
// Stars are clamped to 0...3 via `ItemBadge.clampedStars(_:)` — unit-testable pure fn.

struct ItemBadge: View {

    let stars: Int
    let icon: String
    let count: Int?

    init(stars: Int = 0, icon: String, count: Int? = nil) {
        self.stars = ItemBadge.clampedStars(stars)
        self.icon = icon
        self.count = count
    }

    // MARK: — Pure helper (unit-tested in ComponentHelperTests)

    static func clampedStars(_ count: Int) -> Int {
        min(3, max(0, count))
    }

    // MARK: — Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: AppSpacing.xs) {
                starsRow
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(AppSpacing.md)
            .cardSurface()

            if let count {
                countBadge(count)
                    .offset(x: 6, y: 6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(badgeLabel)
    }

    // MARK: — Sub-views

    private var starsRow: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { idx in
                Image(systemName: idx < stars ? "star.fill" : "star")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(idx < stars ? AppColors.tertiary : AppColors.outlineVariant)
            }
        }
    }

    private func countBadge(_ value: Int) -> some View {
        Text("\(value)")
            .font(AppTypography.labelSmall)
            .foregroundStyle(AppColors.onPrimary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(AppColors.primary, in: Capsule())
    }

    private var badgeLabel: Text {
        var label = "\(stars) stars, \(icon)"
        if let count { label += ", \(count)" }
        return Text(label)
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 16) {
        ItemBadge(stars: 3, icon: "lightbulb.fill", count: 5)
        ItemBadge(stars: 1, icon: "clock.fill")
        ItemBadge(icon: "bolt.fill", count: 12)
    }
    .padding()
    .background(AppColors.background.ignoresSafeArea())
}
