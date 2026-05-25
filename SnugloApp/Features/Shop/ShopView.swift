import SwiftUI

// MARK: — ShopView (Screen 10)
// Design reference: Designs/html/10-shop.html
//
// SHOP tab — 5 SKU placeholders (Coming Soon / disabled).
// Real StoreKit implementation: Faz G.

private struct SKU {
    let id: String
    let title: String
    let description: String
    let price: String
    let isFeatured: Bool
    let badge: String?
    let symbol: String
    let accentColor: Color
}

private let skus: [SKU] = [
    SKU(
        id: "snuglo_plus",
        title: "Snuglo Plus",
        description: "Ad-free meditative experience\nUnlimited daily hints\nExclusive pastel themes",
        price: "$4.99/mo",
        isFeatured: true,
        badge: nil,
        symbol: "sparkles",
        accentColor: AppColors.primary
    ),
    SKU(
        id: "hints_5",
        title: "5 Hints",
        description: "A little nudge when you need it",
        price: "$0.99",
        isFeatured: false,
        badge: nil,
        symbol: "lightbulb.fill",
        accentColor: AppColors.blockCream
    ),
    SKU(
        id: "hints_25",
        title: "25 Hints",
        description: "Great value for puzzle lovers",
        price: "$2.99",
        isFeatured: false,
        badge: "POPULAR",
        symbol: "lightbulb.max.fill",
        accentColor: AppColors.blockPeach
    ),
    SKU(
        id: "hints_unlimited",
        title: "Unlimited Hints",
        description: "Never get stuck again",
        price: "$6.99",
        isFeatured: false,
        badge: nil,
        symbol: "infinity.circle.fill",
        accentColor: AppColors.blockSage
    ),
    SKU(
        id: "remove_ads",
        title: "Remove Ads",
        description: "One-time purchase — permanent",
        price: "$3.99",
        isFeatured: false,
        badge: nil,
        symbol: "xmark.circle.fill",
        accentColor: AppColors.blockLavender
    )
]

struct ShopView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                shopContent
            }

            BottomTabBar()
        }
        .navigationBarHidden(true)
        .onAppear { router.selectedTab = .shop }
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)

            Spacer()

            Text("Snuglo")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
    }

    // MARK: — Shop content

    private var shopContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Shop")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)

                    Text("Enhance your cozy experience")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                // Featured SKU (Snuglo Plus)
                if let featured = skus.first(where: { $0.isFeatured }) {
                    featuredCard(featured)
                }

                // Hints section
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Hints")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)

                    ForEach(skus.filter { !$0.isFeatured && $0.id.contains("hints") }, id: \.id) { sku in
                        hintRow(sku)
                    }
                }

                // Remove Ads
                if let removeAds = skus.first(where: { $0.id == "remove_ads" }) {
                    removeAdsRow(removeAds)
                }

                // Restore button
                Button {
                    // Faz G: StoreKit restore
                } label: {
                    Text("Restore Purchases")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.5)

                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: — Featured card (Snuglo Plus)

    private func featuredCard(_ sku: SKU) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: sku.symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.onPrimary)

                Text(sku.title)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onPrimary)

                Spacer()
            }

            Text(sku.description)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onPrimary.opacity(0.85))

            Button {
                // Faz G: StoreKit purchase
            } label: {
                Text("Subscribe \(sku.price)")
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm + 4)
                    .background(AppColors.onPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(true)
        }
        .padding(AppSpacing.md + 4)
        .background(AppColors.primary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadowL1()
    }

    // MARK: — Hint row

    private func hintRow(_ sku: SKU) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(sku.accentColor.opacity(0.4))
                    .frame(width: 44, height: 44)
                Image(systemName: sku.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(sku.title)
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.onSurface)

                    if let badge = sku.badge {
                        Text(badge)
                            .font(AppTypography.labelSmall)
                            .tracking(0.6)
                            .textCase(.uppercase)
                            .foregroundStyle(AppColors.onPrimary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(AppColors.primary)
                            .clipShape(Capsule())
                    }
                }

                Text(sku.description)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()

            // Price button — disabled
            Text(sku.price)
                .font(AppTypography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
                .padding(.horizontal, AppSpacing.sm + 4)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.primaryContainer.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .stroke(AppColors.primaryContainer, lineWidth: 1)
                )
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        .shadowL1()
    }

    // MARK: — Remove Ads row

    private func removeAdsRow(_ sku: SKU) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("One-Time Purchases")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(sku.accentColor.opacity(0.4))
                        .frame(width: 44, height: 44)
                    Image(systemName: sku.symbol)
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.primary)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(sku.title)
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.onSurface)
                    Text(sku.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Spacer()

                Text(sku.price)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.sm + 4)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primaryContainer.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.primaryContainer, lineWidth: 1)
                    )
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            .shadowL1()
        }
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        ShopView()
    }
    .environment(AppRouter())
}
