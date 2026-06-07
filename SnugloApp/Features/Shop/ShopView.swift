import SwiftUI
import StoreKit

// MARK: — ShopView (Screen 10 · Faz 4: Shop Yenileme)
// Design reference: Designs/html/10-shop.html
// Sections: BalanceHeader (sticky) · Daily Deal · Coin Packs · Exchange · Bundle IAPs · #if DEBUG

struct ShopView: View {

    @Environment(AppRouter.self) private var router

    @State private var viewModel = ShopViewModel()
    @State private var ready = false
    private let store = StoreManager.shared
    private let ads   = AdsManager.shared

    var body: some View {
        // Navigate instantly → show a loading view → reveal content once products
        // are loaded (and after the transition settles, so the heavy content build
        // never blocks the tab tap → no "System gesture gate timed out").
        LoadingGate(isReady: ready) {
            shopContent
        }
        // Root nav bar hidden — Shop's own BalanceHeader is its header. A visible
        // root nav bar here (while sibling tabs hide theirs) made the `.page`
        // TabView crash mid-swipe with "top item belongs to a different navigation
        // bar" as two pages' bars briefly coexisted. All tab roots must be bar-consistent.
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.shop")
        .task {
            await store.loadProducts()
            ready = true
        }
    }

    private var shopContent: some View {
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
        .safeAreaInset(edge: .top) {
            BalanceHeader()
        }
        .overlay(alignment: .top) {
            // Success now celebrates with the centred RewardPopup; this top banner
            // is only for warnings (insufficient balance / ad not ready).
            if viewModel.showClaimedBanner && !viewModel.claimSucceeded {
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
        .overlay(alignment: .top) {
            if viewModel.showExchangeBanner {
                exchangeBanner
                    .padding(.top, AppSpacing.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 3_200_000_000)
                            viewModel.dismissExchangeBanner()
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showExchangeBanner)
    }

    // MARK: — Sections

    private var dailyDealSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.deal.section")
            DailyDealCard(deal: viewModel.currentDeal,
                          canClaim: viewModel.canClaimDeal,
                          onClaim: viewModel.claimDeal)
        }
    }

    // Section header with an optional clarifying subtitle.
    private func sectionHeader(_ title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.onSurface)
            Text(subtitle)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    private var coinPacksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("shop.packs.section", subtitle: "shop.packs.hint")
            CurrencyPackGrid(
                packs: CurrencyPack.allPacks,
                onWatch: viewModel.watchAdForPack,
                adsAvailable: ads.rewardedAvailable
            )
        }
    }

    private var exchangeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("shop.exchange.section", subtitle: "shop.exchange.hint")
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

    @ViewBuilder
    private var claimedBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            if viewModel.claimSucceeded {
                if let currency = viewModel.claimedCurrency {
                    CurrencyIcon(currency: currency, size: 20)
                        .accessibilityHidden(true)
                }
                Text(verbatim: "+\(viewModel.claimedAmount)")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                    .monospacedDigit()
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(AppColors.error)
                    .accessibilityHidden(true)
                Text(viewModel.claimedCurrency == nil ? "shop.claim.adNotReady" : "shop.claim.insufficient")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurface)
            }
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

    // MARK: — Exchange banner

    private var exchangeBanner: some View {
        let isInsufficient = viewModel.exchangeInsufficient != nil
        return ExchangeSignBanner(
            titleKey: isInsufficient ? "shop.exchange.insufficient.title" : "shop.exchange.success.title",
            receipt: isInsufficient ? nil : viewModel.lastExchange,
            messageKey: isInsufficient ? "shop.exchange.insufficient.message" : nil,
            onDismiss: viewModel.dismissExchangeBanner
        )
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
