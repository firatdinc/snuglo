import SwiftUI

// MARK: — StatsShareCard
// A branded, shareable snapshot of the player's lifetime stats. Rendered to an
// image via ImageRenderer and shared with ShareLink. Single-palette.

struct StatsShareCard: View {
    let levels: Int
    let stars: Int
    let perfect: Int
    let longestStreak: Int

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(verbatim: "SNUGLO")
                .font(AppTypography.labelSmall)
                .tracking(4)
                .foregroundStyle(AppColors.onSurfaceVariant)

            MascotView(name: "mascot-tiger", size: 88, celebrate: false)

            Text("stats.share.title")
                .font(AppTypography.headlineLarge)
                .foregroundStyle(AppColors.onSurface)

            VStack(spacing: AppSpacing.md) {
                row(icon: "checkmark.circle.fill", value: "\(levels)", labelKey: "stats.levelsCompleted")
                row(icon: "star.fill", value: "\(stars)", labelKey: "stats.starsEarned")
                row(icon: "sparkles", value: "\(perfect)", labelKey: "stats.perfectSolves")
                row(icon: "crown.fill", value: "\(longestStreak)", labelKey: "stats.longestStreak")
            }
        }
        .padding(AppSpacing.xl)
        .frame(width: 340, height: 460)
        .background(
            LinearGradient(
                colors: [AppColors.primaryContainer.opacity(0.5), AppColors.surfaceContainerLowest],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private func row(icon: String, value: String, labelKey: LocalizedStringKey) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.primary)
                .frame(width: 28)
            Text(labelKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
            Spacer()
            Text(verbatim: value)
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
                .monospacedDigit()
        }
        .frame(width: 240)
    }
}
