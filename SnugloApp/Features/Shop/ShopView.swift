import SwiftUI
import StoreKit

// MARK: — ShopView (Screen 10 · H-1: Localized)
// Design reference: Designs/html/10-shop.html
// Faz G-1: Canlı StoreKit 2 IAP — 5 SKU.
// H-1: All user-visible strings → LocalizedStringKey / NSLocalizedString.
//
// Sections:
//   1. Pack Unlocks   (spice-route / mambo-nights / woodland-retreat)
//   2. Hints          (com.snuglo.hints.small — consumable, +10)
//   3. Remove Ads     (com.snuglo.removeads — non-consumable)
//   4. Restore Purchases

struct ShopView: View {

    @Environment(AppRouter.self) private var router

    private let store    = StoreManager.shared
    private let progress = ProgressStore.shared

    @State private var isPurchasing: Bool    = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header
                packUnlocksSection
                hintsSection
                removeAdsSection
                Divider().padding(.vertical, AppSpacing.xs)
                restoreButton
                hintCountBadge
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl + 32)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("shop.title")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadProducts() }
        .overlay {
            if store.isLoading || isPurchasing { loadingOverlay }
        }
        .alert("common.error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { errorMessage = nil }
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
        .onChange(of: store.lastError) { _, newValue in
            if let e = newValue { errorMessage = e }
        }
    }

    // MARK: — Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("shop.title")
                .font(AppTypography.headlineLarge)
                .tracking(-0.6)
                .foregroundStyle(AppColors.onSurface)
            Text("shop.enhance")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }

    // MARK: — Pack Unlocks

    private var packUnlocksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.packUnlocks")
            packCard(packId: "spice-route",      productID: .packSpice,    icon: "cup.and.saucer.fill", accent: AppColors.blockPeach)
            packCard(packId: "mambo-nights",     productID: .packMambo,    icon: "moon.stars.fill",     accent: AppColors.blockBlush)
            packCard(packId: "woodland-retreat", productID: .packWoodland, icon: "tree.fill",           accent: AppColors.blockSage)
        }
    }

    private func packCard(
        packId: String,
        productID: StoreManager.ProductID,
        icon: String,
        accent: Color
    ) -> some View {
        let pack    = MockData.allPacks.first(where: { $0.id == packId })
        let product = store.product(for: productID)
        let owned   = store.isPurchased(productID)

        return HStack(spacing: AppSpacing.md) {
            iconTile(systemName: icon, accent: owned ? accent : AppColors.surfaceContainerHigh, tint: owned ? AppColors.primary : AppColors.onSurfaceVariant)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: pack?.title ?? packId)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(verbatim: pack?.subtitle ?? "")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()

            purchaseButton(label: owned ? nil : (product?.displayPrice ?? "—"), isOwned: owned) {
                guard let product else { return }
                await performPurchase(product)
            }
        }
        .itemCard(owned: owned)
    }

    // MARK: — Hints

    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.hintsSection")

            let product = store.product(for: .hintsSmall)

            HStack(spacing: AppSpacing.md) {
                iconTile(systemName: "lightbulb.fill", accent: AppColors.tertiary.opacity(0.15), tint: AppColors.tertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("sku.hintsSmall.title")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text(verbatim: String(format: NSLocalizedString("shop.hintsRemaining", comment: ""), progress.hintCount))
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Spacer()

                // Consumable: always buyable
                purchaseButton(label: product?.displayPrice ?? "—", isOwned: false) {
                    guard let product else { return }
                    await performPurchase(product)
                }
            }
            .itemCard(owned: false)
        }
    }

    // MARK: — Remove Ads

    private var removeAdsSection: some View {
        let owned   = store.adsRemoved
        let product = store.product(for: .removeAds)

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("shop.oneTime")

            HStack(spacing: AppSpacing.md) {
                iconTile(
                    systemName: owned ? "checkmark.shield.fill" : "xmark.circle.fill",
                    accent: owned ? AppColors.primaryContainer.opacity(0.5) : AppColors.surfaceContainerHigh,
                    tint: owned ? AppColors.primary : AppColors.onSurfaceVariant
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("sku.removeAds.title")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text("sku.removeAds.body")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Spacer()

                purchaseButton(label: owned ? nil : (product?.displayPrice ?? "—"), isOwned: owned) {
                    guard let product else { return }
                    await performPurchase(product)
                }
            }
            .itemCard(owned: owned)
        }
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
        .disabled(store.isLoading || isPurchasing)
    }

    // MARK: — Hint count

    private var hintCountBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.tertiary)
            Text(verbatim: String(format: NSLocalizedString("shop.hintsAvailable", comment: ""), progress.hintCount))
                .font(AppTypography.labelSmall)
                .tracking(0.3)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: — Loading overlay

    private var loadingOverlay: some View {
        ZStack {
            AppColors.background.opacity(0.6).ignoresSafeArea()
            ProgressView().tint(AppColors.primary).scaleEffect(1.4)
        }
    }

    // MARK: — Shared components

    private func iconTile(systemName: String, accent: Color, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent)
                .frame(width: 48, height: 48)
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundStyle(tint)
        }
    }

    private func purchaseButton(
        label: String?,
        isOwned: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button { Task { await action() } } label: {
            if isOwned {
                Label("shop.owned", systemImage: "checkmark")
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.sm + 2)
                    .padding(.vertical, AppSpacing.sm)
            } else {
                Text(verbatim: label ?? "—")
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.sm + 2)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.primary, lineWidth: 1.5)
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isOwned || isPurchasing)
    }

    /// H-1: Accepts LocalizedStringKey so callers pass translation keys directly.
    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppTypography.headlineSmall)
            .foregroundStyle(AppColors.onSurface)
            .padding(.horizontal, AppSpacing.xs)
    }

    private func performPurchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        _ = await store.purchase(product)
    }
}

// MARK: — View modifier helpers

private extension View {
    func itemCard(owned: Bool) -> some View {
        self
            .padding(AppSpacing.md)
            .background(
                AppColors.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(
                        owned ? AppColors.primary.opacity(0.3) : AppColors.outlineVariant.opacity(0.3),
                        lineWidth: 0.5
                    )
            )
            .shadowL1()
    }
}

#Preview {
    NavigationStack {
        ShopView()
            .environment(AppRouter())
    }
}
