import SwiftUI

// MARK: — UndoRewardedSheet
// Bottom sheet shown when the player taps Undo without enough gems.
// "Watch Ad" triggers AdsManager.showRewarded → GameView applies undoLastMove.

struct UndoRewardedSheet: View {

    let onWatchAd: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var adAvailable: Bool { AdsManager.shared.rewardedAvailable }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primaryContainer)
                    .frame(width: 64, height: 64)
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.top, AppSpacing.md)

            // Text
            VStack(spacing: AppSpacing.xs) {
                Text("Geri Al — Ücretsiz")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text("Kısa bir reklam izle, son yerleştirdiğin parça tepsiye dönsün.")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            // Buttons
            VStack(spacing: AppSpacing.sm) {
                Button {
                    onWatchAd()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 16))
                        Text("Reklam İzle")
                            .font(AppTypography.headlineSmall)
                    }
                    .foregroundStyle(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GameButtonStyle(variant: .primary))
                .disabled(!adAvailable)
                .opacity(adAvailable ? 1 : 0.45)
                .padding(.horizontal, AppSpacing.lg)

                if !adAvailable {
                    Text("Şu an reklam mevcut değil")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("İptal")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, AppSpacing.xl)
        .background(AppColors.background)
    }
}
