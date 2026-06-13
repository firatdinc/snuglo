import SwiftUI

// MARK: — LevelFailSheet
// Centered popup shown when the countdown reaches zero without solving.
// The area behind it is frosted (.ultraThinMaterial) so the board stays
// visible but blurred. Presented as an overlay (not a fullScreenCover) so the
// blur actually samples the game underneath.

struct LevelFailSheet: View {

    let onRetry: () -> Void
    let onHome: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Frosted backdrop — blurs the board behind, absorbs taps.
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .overlay(AppColors.background.opacity(0.25).ignoresSafeArea())
                .opacity(appeared ? 1 : 0)
                .contentShape(Rectangle())
                .accessibilityHidden(true)

            // Popup card
            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppColors.error.opacity(0.12))
                        .frame(width: 92, height: 92)
                    Image(systemName: "clock.badge.xmark.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(AppColors.error)
                }

                VStack(spacing: AppSpacing.sm) {
                    Text("fail.title")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.4)
                        .foregroundStyle(AppColors.onSurface)

                    Text("fail.message")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.sm)
                }

                VStack(spacing: AppSpacing.sm) {
                    Button { onRetry() } label: {
                        Text("common.retry")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GameButtonStyle(variant: .primary))

                    Button { onHome() } label: {
                        Text("pause.home")
                            .font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.surfaceContainerLowest)
            )
            .shadowL1()
            .padding(.horizontal, AppSpacing.xl)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            let anim: Animation? = reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.78)
            withAnimation(anim) { appeared = true }
        }
    }
}
