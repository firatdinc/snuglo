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
        VStack(spacing: AppSpacing.sm) {
            // Icon in a soft tinted disc.
            ZStack {
                Circle()
                    .fill(pack.earn.tint.opacity(0.14))
                    .frame(width: 52, height: 52)
                CurrencyIcon(currency: pack.earn, size: 30)
            }
            .accessibilityHidden(true)

            // What you get — large and dominant.
            Text(verbatim: "+\(pack.amount)")
                .font(AppTypography.headlineMedium)
                .monospacedDigit()
                .foregroundStyle(AppColors.onSurface)

            Text(LocalizedStringKey(pack.titleKey))
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Clear CTA — filled when an ad is ready, muted otherwise.
            Group {
                if adsAvailable {
                    Label("shop.pack.watch.ad", systemImage: "play.fill")
                        .font(AppTypography.labelSmall.weight(.bold))
                        .foregroundStyle(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(AppColors.primary, in: Capsule())
                } else {
                    Text("shop.ad.unavailable")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(AppColors.surfaceContainerHigh, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(
            AppColors.surfaceContainerLowest,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        // Diagonal "FREE" corner ribbon — these packs cost nothing but a short video.
        .overlay(alignment: .topTrailing) {
            Text("shop.free")
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(AppColors.onPrimary)
                .padding(.horizontal, 26)
                .padding(.vertical, 3)
                .background(AppColors.tertiary)
                .rotationEffect(.degrees(45))
                .offset(x: 22, y: 11)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadowL1()
        .contentShape(Rectangle())
        .onTapGesture { if adsAvailable { onWatch(pack) } }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("shop.pack.watch.\(pack.id)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: — Preview

#Preview {
    CurrencyPackGrid(packs: CurrencyPack.allPacks, onWatch: { _ in }, adsAvailable: true)
        .padding()
        .background(AppColors.background)
}
