import SwiftUI

// MARK: — AchievementToast
// A slim banner shown when an achievement unlocks. Self-contained, single-palette.

struct AchievementToast: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle().fill(AppColors.tertiary.opacity(0.22)).frame(width: 40, height: 40)
                Image(systemName: achievement.sfSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.tertiary)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("achievement.unlocked.banner.title")
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                Text(achievement.displayNameKey)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.primary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.tertiary.opacity(0.35), lineWidth: 1)
        )
        .shadowL1()
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}
