import SwiftUI
import StoreKit

// MARK: — BundleSection

/// The five existing IAP SKUs: 3 pack unlocks, 10 hints, remove ads.
/// Self-contained: owns `isPurchasing` and `errorMessage` state.
struct BundleSection: View {

    let store: StoreManager
    let progress: ProgressStore

    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel("shop.packUnlocks")
            packCard(packId: "spice-route", productID: .packSpice, icon: "cup.and.saucer.fill", accent: AppColors.blockPeach, itemIndex: 0)
            packCard(packId: "mambo-nights", productID: .packMambo, icon: "moon.stars.fill", accent: AppColors.blockBlush, itemIndex: 1)
            packCard(packId: "woodland-retreat", productID: .packWoodland, icon: "tree.fill", accent: AppColors.blockSage, itemIndex: 2)

            sectionLabel("shop.hintsSection")
            hintsRow

            sectionLabel("shop.oneTime")
            removeAdsRow
        }
        .overlay {
            if isPurchasing {
                ZStack {
                    AppColors.background.opacity(0.5)
                    ProgressView().tint(AppColors.primary)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            }
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

    // MARK: — Pack row

    private func packCard(
        packId: String,
        productID: StoreManager.ProductID,
        icon: String,
        accent: Color,
        itemIndex: Int
    ) -> some View {
        let pack     = MockData.allPacks.first(where: { $0.id == packId })
        let product  = store.product(for: productID)
        let owned    = store.isPurchased(productID)
        let priceStr = product?.displayPrice ?? "—"
        let localizedTitle = pack.map { NSLocalizedString($0.rawTitleKey, comment: "") } ?? packId

        return HStack(spacing: AppSpacing.md) {
            iconTile(
                systemName: icon,
                accent: owned ? accent : AppColors.surfaceContainerHigh,
                tint: owned ? AppColors.primary : AppColors.onSurfaceVariant
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(pack?.titleKey ?? LocalizedStringKey(packId))
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(pack?.gridLabelKey ?? "")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer(minLength: 0)

            purchaseButton(label: owned ? nil : priceStr, isOwned: owned) {
                guard let product else { return }
                await performPurchase(product)
            }
            .accessibilityLabel(owned
                ? "\(localizedTitle). Owned"
                : "\(localizedTitle). \(priceStr). Tap to purchase"
            )
        }
        .bundleItemCard(owned: owned)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shop.pack_item.\(itemIndex)")
    }

    // MARK: — Hints row

    private var hintsRow: some View {
        let product  = store.product(for: .hintsSmall)
        let priceStr = product?.displayPrice ?? "—"

        return HStack(spacing: AppSpacing.md) {
            iconTile(
                systemName: "lightbulb.fill",
                accent: AppColors.tertiary.opacity(0.15),
                tint: AppColors.tertiary
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("sku.hintsSmall.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(verbatim: String(format: NSLocalizedString("shop.hintsRemaining", comment: ""), progress.hintCount))
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer(minLength: 0)

            purchaseButton(label: priceStr, isOwned: false) {
                guard let product else { return }
                await performPurchase(product)
            }
            .accessibilityLabel("10 Hints. \(priceStr). Tap to purchase")
        }
        .bundleItemCard(owned: false)
    }

    // MARK: — Remove Ads row

    private var removeAdsRow: some View {
        let owned    = store.adsRemoved
        let product  = store.product(for: .removeAds)
        let priceStr = product?.displayPrice ?? "—"

        return HStack(spacing: AppSpacing.md) {
            iconTile(
                systemName: owned ? "checkmark.shield.fill" : "xmark.circle.fill",
                accent: owned ? AppColors.primaryContainer.opacity(0.5) : AppColors.surfaceContainerHigh,
                tint: owned ? AppColors.primary : AppColors.onSurfaceVariant
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("sku.removeAds.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text("sku.removeAds.body")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer(minLength: 0)

            purchaseButton(label: owned ? nil : priceStr, isOwned: owned) {
                guard let product else { return }
                await performPurchase(product)
            }
            .accessibilityLabel(owned
                ? "Remove Ads. Owned"
                : "Remove Ads. \(priceStr). Tap to purchase"
            )
        }
        .bundleItemCard(owned: owned)
    }

    // MARK: — Shared helpers

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

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppTypography.headlineMedium)
            .foregroundStyle(AppColors.onSurface)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.top, AppSpacing.xs)
    }

    private func performPurchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        _ = await store.purchase(product)
    }
}

// MARK: — Local view modifier

private extension View {
    func bundleItemCard(owned: Bool) -> some View {
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
