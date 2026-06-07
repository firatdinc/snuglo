import SwiftUI

// MARK: — DailyDealCard
//
// Bold featured "hero" offer at the top of the shop. Gradient backdrop, a
// "TODAY ONLY" badge, large reward read-out, and a prominent 3D CTA — the
// highest-visual-weight element on the screen (featured-offer pattern from
// top casual games). Theme tokens only.

struct DailyDealCard: View {

    let deal: DailyDeal
    var canClaim: Bool = true
    let onClaim: () -> Void

    private var reward: (currency: Currency, amount: Int) {
        switch deal.action {
        case .watchAd(let earn, let amount):       return (earn, amount)
        case .spend(_, _, let earn, let amount):   return (earn, amount)
        }
    }

    private var isWatchAd: Bool {
        if case .watchAd = deal.action { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Top row: badge + reward.
            HStack(alignment: .top) {
                Label("shop.deal.section", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.onPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 5)
                    .background(AppColors.primary, in: Capsule())

                Spacer(minLength: 0)

                // Big reward read-out.
                HStack(spacing: 5) {
                    Text(verbatim: "+\(reward.amount)")
                        .font(AppTypography.headlineLarge)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.onSurface)
                    CurrencyIcon(currency: reward.currency, size: 26)
                }
                .accessibilityHidden(true)
            }

            // Title + message with a glossy icon.
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(reward.currency.tint.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: deal.sfSymbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(reward.currency.tint)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(deal.titleKey))
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Text(LocalizedStringKey(deal.messageKey))
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            // Prominent 3D CTA.
            Button(action: onClaim) {
                Label {
                    Text(isWatchAd ? "shop.pack.watch.ad" : "shop.deal.claim")
                } icon: {
                    Image(systemName: isWatchAd ? "play.fill" : "gift.fill")
                }
                .labelStyle(.titleAndIcon)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(canClaim ? AppColors.onPrimary : AppColors.onSurfaceVariant)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GameButtonStyle(variant: canClaim ? .primary : .muted))
            .disabled(!canClaim)
            .accessibilityIdentifier("shop.deal.claim.\(deal.id)")
        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [
                    AppColors.primaryContainer.opacity(0.45),
                    AppColors.surfaceContainerLowest
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.primary.opacity(0.25), lineWidth: 1)
        )
        .shadowL1()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shop.daily.deal.card")
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 16) {
        DailyDealCard(deal: DailyDeal.allDeals[0], onClaim: {})
        DailyDealCard(deal: DailyDeal.allDeals[3], onClaim: {})
    }
    .padding()
    .background(AppColors.background)
}
