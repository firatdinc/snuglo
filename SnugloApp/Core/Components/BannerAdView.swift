import SwiftUI

// MARK: — BannerAdView
// 50 pt tall bottom banner placeholder. Shown only when ads are NOT removed.
// FAZ-J: Replace body with GADBannerView wrapped in UIViewRepresentable.
//
// Usage: Place at the bottom of MainMenuView, LevelsListView, etc.
//   VStack(spacing: 0) {
//       // ... content ...
//       BannerAdView()
//   }

struct BannerAdView: View {

    @State private var ads = AdsManager.shared

    var body: some View {
        if ads.shouldShowBanner {
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text("ad.advertisement")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                    Text("ad.bannerPlaceholder")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
            .background(AppColors.surfaceContainerLow)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(AppColors.outlineVariant.opacity(0.5)),
                alignment: .top
            )
            // FAZ-J: Replace entire body with UIViewRepresentable(GADBannerView)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Content")
        Spacer()
        BannerAdView()
    }
    .background(AppColors.background)
}
