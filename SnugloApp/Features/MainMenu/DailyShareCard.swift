import SwiftUI

// MARK: — DailyShareCard
// A branded, shareable card celebrating the player's daily puzzle streak.
// Rendered to an image via ImageRenderer and shared with ShareLink.
// Single-palette; self-contained.

struct DailyShareCard: View {
    let streak: Int
    let daysSolved: Int
    let dateText: String

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(verbatim: "SNUGLO")
                .font(AppTypography.labelSmall)
                .tracking(4)
                .foregroundStyle(AppColors.onSurfaceVariant)

            MascotView(name: "mascot-rabbit", size: 96, celebrate: false)

            Text("daily.share.title")
                .font(AppTypography.headlineLarge)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)

            HStack(spacing: AppSpacing.xl) {
                stat(value: "\(streak)", labelKey: "menu.streak.day")
                stat(value: "\(daysSolved)", labelKey: "daily.share.solved")
            }

            Text(verbatim: dateText)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .padding(AppSpacing.xl)
        .frame(width: 340, height: 440)
        .background(
            LinearGradient(
                colors: [AppColors.blushAccent, AppColors.surfaceContainerLowest],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private func stat(value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(AppTypography.numericLarge)
                .foregroundStyle(AppColors.primary)
            Text(labelKey)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }
}
