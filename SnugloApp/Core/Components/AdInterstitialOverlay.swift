import SwiftUI

// MARK: — AdInterstitialOverlay
// Full-window overlay shown while an interstitial ad is presenting.
// Faz G-2 placeholder: renders a loading indicator instead of a real ad.
// FAZ-J: Remove this view entirely; AdMob SDK handles its own presentation
//         via a UIViewController — this overlay is only needed for the placeholder.

struct AdInterstitialOverlay: View {

    @State private var ads = AdsManager.shared

    var body: some View {
        if ads.isShowingInterstitial {
            ZStack {
                // Dim background
                AppColors.surfaceContainerHigh
                    .opacity(0.96)
                    .ignoresSafeArea()

                // Ad card placeholder
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))

                    Text("Ad")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)

                    Text("Reklam yükleniyor… (placeholder)")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)

                    ProgressView()
                        .tint(AppColors.primary)
                        .padding(.top, AppSpacing.xs)
                }
                .padding(AppSpacing.xl)
                .background(AppColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .shadowL1()
                .padding(.horizontal, AppSpacing.lg)
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        // Force show by creating a local AdsManager with isShowingInterstitial = true
        // (Preview-only: real view drives off AdsManager.shared)
        VStack {
            Text("Game Content Behind Ad")
                .font(AppTypography.headlineLarge)
        }
        AdInterstitialOverlay()
    }
}
