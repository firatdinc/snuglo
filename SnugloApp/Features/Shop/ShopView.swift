import SwiftUI
import StoreKit

// MARK: — ShopView (Screen 10 · Faz 4: Shop Yenileme)
// Design reference: Designs/html/10-shop.html
// Sections: BalanceHeader (sticky) · Daily Deal · Coin Packs · Exchange · Bundle IAPs · #if DEBUG

struct ShopView: View {

    @Environment(AppRouter.self) private var router

    @State private var viewModel = ShopViewModel()
    private let store = StoreManager.shared
    private let ads   = AdsManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                dailyDealSection
                coinPacksSection
                exchangeSection
                bundleSection
                #if DEBUG
                debugSection
                #endif
                restoreButton
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl + 32)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("shop.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.shop")
        .task { await store.loadProducts() }
        .safeAreaInset(edge: .top) {
            BalanceHeader()
        }
        .overlay(alignment: .top) {
            if viewModel.showClaimedBanner {
                claimedBanner
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            viewModel.dismissBanner()
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showClaimedBanner)
    }

    // MARK: — Sections

    private var dailyDealSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.deal.section")
            DailyDealCard(deal: viewModel.currentDeal, onClaim: viewModel.claimDeal)
        }
    }

    private var coinPacksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.packs.section")
            CurrencyPackGrid(
                packs: CurrencyPack.allPacks,
                onWatch: viewModel.watchAdForPack,
                adsAvailable: ads.rewardedAvailable
            )
        }
    }

    private var exchangeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.exchange.section")
            ExchangePanel(viewModel: viewModel)
        }
    }

    private var bundleSection: some View {
        BundleSection(store: store, progress: ProgressStore.shared)
    }

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.debug.section")
            DebugSection()
        }
    }
    #endif

    // MARK: — Restore

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("shop.restore")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Restores any previously purchased items")
    }

    // MARK: — Claimed banner

    private var claimedBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            if let currency = viewModel.claimedCurrency {
                CurrencyIcon(currency: currency, size: 20)
                    .accessibilityHidden(true)
            }
            Text(verbatim: "+\(viewModel.claimedAmount)")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
                .monospacedDigit()
            Spacer(minLength: 0)
            Button { viewModel.dismissBanner() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            AppColors.surfaceContainerLowest,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .shadowL1()
    }

    // MARK: — Helpers

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppTypography.headlineMedium)
            .foregroundStyle(AppColors.onSurface)
            .padding(.horizontal, AppSpacing.xs)
    }
}

#Preview {
    NavigationStack {
        ShopView()
            .environment(AppRouter())
    }
}
