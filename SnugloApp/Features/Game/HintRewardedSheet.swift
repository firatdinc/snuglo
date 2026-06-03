import SwiftUI

// MARK: — HintRewardedSheet
// Shown when the player taps Hint with no hints AND no gems left.
// "Watch Ad" triggers AdsManager.showRewarded → GameView grants + applies a hint.

struct HintRewardedSheet: View {

    let onWatchAd: () -> Void
    let onDismiss: () -> Void

    private var adAvailable: Bool { AdsManager.shared.rewardedAvailable }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryContainer)
                    .frame(width: 64, height: 64)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.top, AppSpacing.md)

            VStack(spacing: AppSpacing.xs) {
                Text("hint.rewarded.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text("hint.rewarded.message")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            VStack(spacing: AppSpacing.sm) {
                Button {
                    onWatchAd()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 16))
                        Text("powerup.watchAd")
                            .font(AppTypography.headlineSmall)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GameButtonStyle(variant: adAvailable ? .primary : .muted))
                .disabled(!adAvailable)

                Button("common.close") { onDismiss() }
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
    }
}
