import SwiftUI

// MARK: — BalanceHeader

/// Sticky header showing coin / gem / ticket balances via BalanceChip × 3.
/// Placed with `.safeAreaInset(edge: .top)` in ShopView.
/// Cup is intentionally excluded — prestige/display-only.
struct BalanceHeader: View {

    private let wallet = WalletStore.shared

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Spacer(minLength: 0)
            BalanceChip(currency: .coin, amount: wallet.coin)
            BalanceChip(currency: .gem, amount: wallet.gem)
            BalanceChip(currency: .ticket, amount: wallet.ticket)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shop.balance.header")
    }
}

// MARK: — Preview

#Preview {
    BalanceHeader()
        .background(AppColors.background)
}
