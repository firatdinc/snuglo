import SwiftUI
import StoreKit

// MARK: — BundleSection

/// The five existing IAP SKUs: 3 pack unlocks, 10 hints, remove ads.
/// Self-contained: owns `isPurchasing` and `errorMessage` state.
struct BundleSection: View {

    let store: StoreManager
    let progress: ProgressStore

    @State private var errorMessage: String?
    @State private var showResultBanner: Bool = false
    // Info popover content (what an item does), shown on the ⓘ tap.
    @State private var infoTitle: LocalizedStringKey?
    @State private var infoBody: LocalizedStringKey?

    private var rc: RevenueCatManager { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Puzzle packs unlock by PROGRESSION now (finish the previous pack),
            // so the shop only sells Hints + Remove Ads (via RevenueCat).
            sectionLabel("shop.hintsSection")
            hintsRow

            sectionLabel("shop.oneTime")
            keysRow
            removeAdsRow
        }
        .overlay {
            if rc.isPurchasing {
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
        // "What does this do?" info popover.
        .alert(infoTitle ?? "", isPresented: Binding(
            get: { infoBody != nil },
            set: { if !$0 { infoBody = nil; infoTitle = nil } }
        )) {
            Button("common.ok", role: .cancel) {}
        } message: {
            if let body = infoBody { Text(body) }
        }
        .onChange(of: rc.lastError) { _, newValue in
            if let e = newValue { errorMessage = e }
        }
        .overlay(alignment: .top) {
            if showResultBanner {
                AnnouncementBanner(
                    titleKey: "shop.iap.purchase.success",
                    messageKey: "shop.iap.purchase.success.message",
                    onDismiss: { showResultBanner = false }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        showResultBanner = false
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showResultBanner)
    }

    // MARK: — Purchases (RevenueCat)

    private func buyHints() async {
        if await rc.purchaseHints() {
            showResultBanner = true
        } else if let e = rc.lastError {
            errorMessage = e
        }
    }

    private func buyRemoveAds() async {
        if await rc.purchaseRemoveAds() {
            showResultBanner = true
        } else if let e = rc.lastError {
            errorMessage = e
        }
    }

    private func buyKeys() async {
        if await rc.purchaseKeys() {
            showResultBanner = true
        } else if let e = rc.lastError {
            errorMessage = e
        }
    }

    // MARK: — Keys row

    private var keysRow: some View {
        let priceStr = rc.keysPrice
        return HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.tertiary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image("Key").resizable().renderingMode(.original).scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("sku.keysSmall.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(verbatim: String(format: NSLocalizedString("shop.keysOwned", comment: ""), ChestStore.shared.keys))
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer(minLength: 0)

            purchaseButton(label: priceStr, isOwned: false) {
                await buyKeys()
            }
            .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.buyKeys", comment: ""), priceStr)))
        }
        .bundleItemCard(owned: false)
        .overlay(alignment: .topTrailing) {
            infoBadge(title: "shop.info.keys.title", body: "shop.info.keys.body")
        }
    }

    // MARK: — Hints row

    private var hintsRow: some View {
        let priceStr = rc.hintsPrice

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
                await buyHints()
            }
            .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.buyHints", comment: ""), priceStr)))
        }
        .bundleItemCard(owned: false)
        .overlay(alignment: .topTrailing) {
            infoBadge(title: "shop.info.hints.title", body: "shop.info.hints.body")
        }
    }

    // MARK: — Remove Ads row

    private var removeAdsRow: some View {
        let owned    = rc.hasRemoveAds || store.adsRemoved
        let priceStr = rc.removeAdsPrice

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
                await buyRemoveAds()
            }
            .accessibilityLabel(Text(verbatim: owned
                ? NSLocalizedString("a11y.removeAdsOwned", comment: "")
                : String(format: NSLocalizedString("a11y.buyRemoveAds", comment: ""), priceStr)
            ))
        }
        .bundleItemCard(owned: owned)
        .overlay(alignment: .topTrailing) {
            infoBadge(title: "shop.info.removeAds.title", body: "shop.info.removeAds.body")
        }
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
                // When the StoreKit price is available show it; otherwise a clear
                // "Unlock" with a lock icon (never a bare "—").
                let hasPrice = (label != nil && label != "—")
                HStack(spacing: 5) {
                    Image(systemName: hasPrice ? "cart.fill" : "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                    if hasPrice {
                        Text(verbatim: label!)
                            .font(AppTypography.bodyMedium.weight(.semibold))
                    } else {
                        Text("shop.unlock")
                            .font(AppTypography.bodyMedium.weight(.semibold))
                    }
                }
                .foregroundStyle(AppColors.onPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .fill(AppColors.primary)
                )
            }
        }
        .buttonStyle(.plain)
        .disabled(isOwned || rc.isPurchasing)
    }

    // MARK: — Info badge (what does this item do?)

    private func infoBadge(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        Button {
            infoTitle = title
            infoBody = body
        } label: {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
                .padding(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("a11y.info"))
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppTypography.headlineMedium)
            .foregroundStyle(AppColors.onSurface)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.top, AppSpacing.xs)
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
