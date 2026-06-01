import SwiftUI

// MARK: — BalanceChip
// Pill-shaped chip: CurrencyIcon (left) + balance amount (right, tabular digits).
// Caller is responsible for passing the amount from WalletStore or any other source.
// No global store reference inside — data-agnostic.

struct BalanceChip: View {

    let currency: Currency
    let amount: Int

    init(currency: Currency, amount: Int) {
        self.currency = currency
        self.amount = amount
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            CurrencyIcon(currency: currency, size: 18)
            Text("\(amount)")
                .font(AppTypography.numericSmall)
                .monospacedDigit()
                .foregroundStyle(AppColors.onSurface)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.35), value: amount)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(amount) \(currency.displayNameKey)"))
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 12) {
        BalanceChip(currency: .coin, amount: 1_250)
        BalanceChip(currency: .gem, amount: 34)
        BalanceChip(currency: .ticket, amount: 7)
    }
    .padding()
    .background(AppColors.background.ignoresSafeArea())
}
