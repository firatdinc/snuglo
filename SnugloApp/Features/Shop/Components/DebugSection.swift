#if DEBUG
import SwiftUI

// MARK: — DebugSection

/// Debug wallet controls — compiled out in Release builds.
struct DebugSection: View {

    private let wallet = WalletStore.shared

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            debugButton("shop.debug.add.coins") { wallet.earn(.coin, amount: 500) }
            debugButton("shop.debug.add.gems") { wallet.earn(.gem, amount: 100) }
            debugButton("shop.debug.add.tickets") { wallet.earn(.ticket, amount: 5) }
        }
        .padding(AppSpacing.md)
        .background(
            AppColors.surfaceContainerHigh.opacity(0.5),
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.5), lineWidth: 1)
        )
    }

    private func debugButton(_ key: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .font(AppTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    AppColors.primaryContainer.opacity(0.2),
                    in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DebugSection()
        .padding()
        .background(AppColors.background)
}
#endif
