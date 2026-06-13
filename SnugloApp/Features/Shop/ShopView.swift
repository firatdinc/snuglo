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
                gemStoreSection
                coinPacksSection
                exchangeSection
                bundleSection
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

    // Paid gem packs (RevenueCat IAPs com.snuglo.gems.tier1…5).
    private var gemStoreSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("shop.gems.section", subtitle: "shop.gems.hint")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: AppSpacing.md),
                                GridItem(.flexible(), spacing: AppSpacing.md)],
                      spacing: AppSpacing.md) {
                ForEach(GemPack.catalog) { pack in
                    Button {
                        Task { await buyGem(pack) }
                    } label: {
                        gemPackCard(pack)
                    }
                    .buttonStyle(.plain)
                    .disabled(RevenueCatManager.shared.isPurchasing)
                }
            }
        }
    }

    private func gemPackCard(_ pack: GemPack) -> some View {
        VStack(spacing: AppSpacing.sm) {
            CurrencyIcon(currency: .gem, size: 40)
            Text(verbatim: "+\(pack.gems)")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
            Text(verbatim: RevenueCatManager.shared.displayPrice(for: pack))
                .font(AppTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(AppColors.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(AppColors.primary, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest,
                    in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if pack.bestValue {
                Text("shop.bestValue")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.5)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .foregroundStyle(AppColors.onPrimary)
                    .frame(width: 120, alignment: .center)
                    .padding(.vertical, 3)
                    .background(AppColors.tertiary)
                    .rotationEffect(.degrees(45))
                    .offset(x: 36, y: 18)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadowL1()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.buyGems", comment: ""),
                                                   pack.gems, RevenueCatManager.shared.displayPrice(for: pack))))
    }

    private func buyGem(_ pack: GemPack) async {
        // RC.purchase credits the gems to the wallet on success; celebrate it.
        if await RevenueCatManager.shared.purchase(pack) {
            RewardCenter.shared.showCurrency(.gem, amount: pack.gems)
        }
    }

    private var coinPacksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("shop.packs.section", subtitle: "shop.packs.hint")
            CurrencyPackGrid(
                packs: CurrencyPack.allPacks,
                onWatch: viewModel.watchAdForPack,
                adsAvailable: ads.rewardedReady
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
        .accessibilityHint(Text("a11y.restoreHint"))
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
            .accessibilityLabel(Text("a11y.dismiss"))
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
