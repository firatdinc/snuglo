import SwiftUI

// MARK: — TowerGameOverSheet
// Shown when a Tower climb ends (one mistake). Shows floors cleared + coin
// reward, the best floor, and Retry (costs a ticket) / Home.

struct TowerGameOverSheet: View {

    let floorsCleared: Int
    let coinReward: Int
    let onRetry: () -> Void
    let onHome: () -> Void

    private var canRetry: Bool { TowerStore.shared.canEnter() }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle().fill(AppColors.errorContainer).frame(width: 64, height: 64)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppColors.error)
                }
                .padding(.top, AppSpacing.sm)

                Text("tower.over.title")
                    .font(AppTypography.headlineMedium)
                    .foregroundStyle(AppColors.onSurface)

                Text(verbatim: String(format: NSLocalizedString("tower.over.floors", comment: ""), floorsCleared))
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.onSurfaceVariant)

                HStack(spacing: AppSpacing.xs) {
                    CurrencyIcon(currency: .coin, size: 22)
                    Text(verbatim: "+\(coinReward)")
                        .font(AppTypography.numericLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .monospacedDigit()
                }

                Text(verbatim: String(format: NSLocalizedString("tower.over.best", comment: ""), TowerStore.shared.bestFloor))
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))

                VStack(spacing: AppSpacing.sm) {
                    Button(action: onRetry) {
                        Label {
                            Text(verbatim: String(format: NSLocalizedString("tower.over.retry", comment: ""),
                                                  TowerStore.ticketCost))
                        } icon: {
                            Image(systemName: "ticket.fill")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GameButtonStyle(variant: canRetry ? .primary : .muted))
                    .foregroundStyle(canRetry ? AppColors.onPrimary : AppColors.onSurfaceVariant)
                    .font(AppTypography.headlineSmall)
                    .disabled(!canRetry)

                    Button("tower.over.home", action: onHome)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 340)
            .background(AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL3()
            .padding(AppSpacing.lg)
        }
    }
}
