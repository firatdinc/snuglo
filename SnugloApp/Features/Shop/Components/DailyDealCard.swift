import SwiftUI

// MARK: — DailyDealCard

/// Full-width hero card displaying the current daily deal with a Claim CTA.
struct DailyDealCard: View {

    let deal: DailyDeal
    let onClaim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.primaryContainer.opacity(0.35))
                        .frame(width: 48, height: 48)
                    Image(systemName: deal.sfSymbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(deal.titleKey))
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text(LocalizedStringKey(deal.messageKey))
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button(action: onClaim) {
                Text("shop.deal.claim")
                    .font(AppTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primary, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("shop.deal.claim.\(deal.id)")
        }
        .padding(AppSpacing.md)
        .background(
            AppColors.primaryContainer.opacity(0.12),
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
        )
        .shadowL1()
        .accessibilityIdentifier("shop.daily.deal.card")
    }
}

// MARK: — Preview

#Preview {
    DailyDealCard(deal: DailyDeal.allDeals[0], onClaim: {})
        .padding()
        .background(AppColors.background)
}
