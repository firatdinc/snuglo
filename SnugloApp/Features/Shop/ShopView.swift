import SwiftUI

// MARK: — ShopView
// Ref: Designs/html/10-shop.html
// SHOP tab — 5 SKU cards (all disabled, placeholder for v1.0 launch).
// StoreKit integration: Faz G.

struct ShopView: View {

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // — Header —
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Shop")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)
                    Text("Enhance your cozy experience")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                // — Snuglo Plus subscription card —
                plusCard

                // — Hints section —
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Hints")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                        .padding(.horizontal, AppSpacing.xs)

                    hintCard(count: "5 Hints",        price: "$0.99", badge: nil)
                    hintCard(count: "25 Hints",       price: "$2.99", badge: "POPULAR")
                    hintCard(count: "Unlimited",      price: "$7.99", badge: nil)
                }

                // — Remove Ads —
                removeAdsRow

                // — Restore purchases —
                Button {
                    // StoreKit: Faz G
                } label: {
                    Text("Restore Purchases")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(true)

                Text("Available in v1.0 launch")
                    .font(AppTypography.labelSmall)
                    .tracking(0.3)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Plus card

    private var plusCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Snuglo Plus")
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onPrimary)
                    Text("$4.99 / month")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.onPrimary.opacity(0.8))
                }
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.onPrimary.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                featureRow("Ad-free meditative experience")
                featureRow("Unlimited daily hints")
                featureRow("Exclusive pastel themes")
            }

            Button {} label: {
                Text("Subscribe")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm + 4)
                    .background(AppColors.onPrimary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.7)
        }
        .padding(AppSpacing.md + 4)
        .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadowL1()
    }

    private func featureRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark")
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppColors.onPrimary.opacity(0.9))
    }

    // MARK: — Hint card

    private func hintCard(count: String, price: String, badge: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(count)
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    if let badge {
                        Text(badge)
                            .font(AppTypography.labelSmall)
                            .tracking(0.4)
                            .foregroundStyle(AppColors.onPrimary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(AppColors.primary, in: Capsule())
                    }
                }
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.tertiary)
            }
            Spacer()
            Button {} label: {
                Text(price)
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.primary, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.6)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
    }

    // MARK: — Remove ads row

    private var removeAdsRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Remove Ads")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text("One-time purchase")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            Spacer()
            Button {} label: {
                Text("$3.99")
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.primary, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.6)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
    }
}

#Preview {
    NavigationStack { ShopView() }
        .environment(AppRouter())
}
