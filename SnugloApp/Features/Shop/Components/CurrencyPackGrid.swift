import SwiftUI

// MARK: — CurrencyPackGrid

/// 2-column lazy grid of ad-reward currency packs.
/// Each pack shows a "Watch Ad" button; disabled when no rewarded ad is available.
struct CurrencyPackGrid: View {

    let packs: [CurrencyPack]
    let onWatch: (CurrencyPack) -> Void
    let adsAvailable: Bool

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(packs) { pack in
                packCell(pack)
            }
        }
    }

    private func packCell(_ pack: CurrencyPack) -> some View {
        VStack(spacing: AppSpacing.xs) {
            CurrencyIcon(currency: pack.earn, size: 28)
                .accessibilityHidden(true)

            Text(verbatim: "+\(pack.amount)")
                .font(AppTypography.numericLabel)
                .monospacedDigit()
                .foregroundStyle(AppColors.onSurface)

            Text(LocalizedStringKey(pack.titleKey))
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Button { onWatch(pack) } label: {
                Label("shop.pack.watch.ad", systemImage: "play.fill")
                    .font(AppTypography.labelSmall.weight(.semibold))
                    .foregroundStyle(adsAvailable ? AppColors.primary : AppColors.onSurfaceVariant)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(
                                adsAvailable ? AppColors.primary : AppColors.outlineVariant,
                                lineWidth: 1
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!adsAvailable)
            .accessibilityIdentifier("shop.pack.watch.\(pack.id)")

            if !adsAvailable {
                Text("shop.ad.unavailable")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(
            AppColors.surfaceContainerLowest,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .shadowL1()
    }
}

// MARK: — Preview

#Preview {
    CurrencyPackGrid(packs: CurrencyPack.allPacks, onWatch: { _ in }, adsAvailable: true)
        .padding()
        .background(AppColors.background)
}
