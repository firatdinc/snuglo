import SwiftUI

// MARK: — LeaderboardView (Faz 1: placeholder — full impl in Faz 5)

struct LeaderboardView: View {

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Text("leaderboard.title")
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(AppColors.onSurface)
                    .tracking(-0.6)

                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppColors.tertiary)
                        .accessibilityHidden(true)

                    VStack(spacing: AppSpacing.sm) {
                        Text("leaderboard.placeholder.title")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onSurface)
                            .multilineTextAlignment(.center)

                        Text("leaderboard.placeholder.body")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(AppSpacing.xl)
                .cardSurface()
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.top, AppSpacing.xl)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.leaderboard")
    }
}

#Preview {
    LeaderboardView()
        .environment(AppRouter())
}
