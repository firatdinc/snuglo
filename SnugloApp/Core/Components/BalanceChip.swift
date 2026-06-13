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
            Text(verbatim: "\(amount)")
                .font(AppTypography.numericSmall)
                .monospacedDigit()
                .foregroundStyle(AppColors.onSurface)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.35), value: amount)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        // Glossy, slightly-raised game pill instead of a flat card.
        .background {
            ZStack {
                Capsule().fill(AppColors.surfaceContainerLowest)
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                         startPoint: .top, endPoint: .center))
                Capsule().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.4),
                                            AppColors.outlineVariant.opacity(0.5)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
            }
        }
        .shadowL1()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(amount) " + NSLocalizedString(currency.displayNameKey, comment: "")))
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
