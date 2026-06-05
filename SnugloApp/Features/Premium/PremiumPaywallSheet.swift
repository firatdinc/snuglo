import SwiftUI

// MARK: — PremiumPaywallSheet
// Premium upsell: unlimited energy + no ads + exclusive cosmetics. Purchases via
// RevenueCat (RevenueCatManager). Shown from the energy gate and Profile.

struct PremiumPaywallSheet: View {

    @Environment(AppRouter.self) private var router
    @State private var rc = RevenueCatManager.shared
    @State private var working = false

    private let benefits: [(String, LocalizedStringKey)] = [
        ("bolt.fill",       "paywall.benefit.energy"),
        ("rectangle.slash", "paywall.benefit.ads"),
        ("sparkles",        "paywall.benefit.cosmetics"),
        ("square.grid.2x2.fill", "paywall.benefit.levels"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { dismiss() }

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle().fill(AppColors.primaryContainer).frame(width: 68, height: 68)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }
                .padding(.top, AppSpacing.sm)

                Text("paywall.title")
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(AppColors.onSurface)
                Text("paywall.subtitle")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(Array(benefits.enumerated()), id: \.offset) { _, item in
                        let (icon, key) = item
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                                .frame(width: 26)
                            Text(key)
                                .font(AppTypography.bodyLarge)
                                .foregroundStyle(AppColors.onSurface)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xs)

                Button {
                    Task {
                        working = true
                        if await rc.purchasePremium() { dismiss() }
                        working = false
                    }
                } label: {
                    Text(verbatim: String(format: NSLocalizedString("paywall.cta", comment: ""), rc.premiumPrice))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GameButtonStyle(variant: .primary))
                .foregroundStyle(AppColors.onPrimary)
                .font(AppTypography.headlineSmall)
                .disabled(working)

                Button("paywall.restore") { Task { await rc.restorePurchases(); dismiss() } }
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                Button("button.close") { dismiss() }
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 360)
            .background(AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL3()
            .padding(AppSpacing.lg)
        }
        .task { await rc.loadProducts() }
    }

    private func dismiss() { router.showPaywall = false }
}
