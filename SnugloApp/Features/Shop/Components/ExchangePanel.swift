import SwiftUI

// MARK: — ExchangePanel
//
// Two conversion cards: coin → gem (100:1) and gem → ticket (50:1).
// Each card makes the deal unambiguous:
//   • an explicit rate line  ("100 🪙 = 1 💎")
//   • a live cost → reward preview that tracks the stepper
//   • your current balance of the source currency
//   • a Convert button that, when you can't afford it, says exactly how much
//     more you need instead of just greying out.

struct ExchangePanel: View {

    @Bindable var viewModel: ShopViewModel
    private let wallet = WalletStore.shared

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            exchangeCard(
                from: .coin, to: .gem,
                unitCost: CurrencyRate.coinPerGem,
                amount: $viewModel.coinToGemAmount,
                range: 1...10,
                balance: wallet.coin,
                canAfford: viewModel.canExchangeCoinToGem,
                action: viewModel.exchangeCoinToGem,
                stepperID: "shop.exchange.stepper.coin",
                confirmID: "shop.exchange.confirm.coin"
            )
            exchangeCard(
                from: .gem, to: .ticket,
                unitCost: CurrencyRate.gemPerTicket,
                amount: $viewModel.gemToTicketAmount,
                range: 1...5,
                balance: wallet.gem,
                canAfford: viewModel.canExchangeGemToTicket,
                action: viewModel.exchangeGemToTicket,
                stepperID: "shop.exchange.stepper.gem",
                confirmID: "shop.exchange.confirm.gem"
            )
        }
    }

    // MARK: — One conversion card

    private func exchangeCard(
        from: Currency, to: Currency,
        unitCost: Int,
        amount: Binding<Int>,
        range: ClosedRange<Int>,
        balance: Int,
        canAfford: Bool,
        action: @escaping () -> Void,
        stepperID: String,
        confirmID: String
    ) -> some View {
        let totalCost = amount.wrappedValue * unitCost
        let deficit   = max(0, totalCost - balance)

        return VStack(spacing: AppSpacing.sm) {
            // Rate line + current balance.
            HStack {
                HStack(spacing: 4) {
                    Text("shop.exchange.rate")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    Text(verbatim: "\(unitCost)")
                        .font(AppTypography.labelSmall.weight(.semibold))
                        .foregroundStyle(AppColors.onSurface)
                        .monospacedDigit()
                    CurrencyIcon(currency: from, size: 14)
                    Text(verbatim: "= 1")
                        .font(AppTypography.labelSmall.weight(.semibold))
                        .foregroundStyle(AppColors.onSurface)
                    CurrencyIcon(currency: to, size: 14)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    CurrencyIcon(currency: from, size: 14)
                    Text(verbatim: "\(balance)")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.35), value: balance)
                }
            }

            // Cost → reward preview.
            HStack(spacing: AppSpacing.sm) {
                amountPill(prefix: "−", value: totalCost, currency: from, tint: false)

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.onSurfaceVariant)

                amountPill(prefix: "+", value: amount.wrappedValue, currency: to, tint: true)

                Spacer(minLength: 0)

                Stepper("", value: amount, in: range)
                    .labelsHidden()
                    .accessibilityIdentifier(stepperID)
            }

            // Convert CTA — names the exact deficit when you can't afford it.
            Button(action: action) {
                Group {
                    if canAfford {
                        Text("shop.exchange.confirm")
                    } else {
                        Text(verbatim: String(
                            format: NSLocalizedString("shop.exchange.need", comment: ""),
                            deficit
                        )) + Text(verbatim: " ") + Text(LocalizedStringKey(from.displayNameKey))
                    }
                }
                .font(AppTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(canAfford ? AppColors.onPrimary : AppColors.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    canAfford ? AnyShapeStyle(AppColors.primary)
                              : AnyShapeStyle(AppColors.surfaceContainerHigh),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
            .accessibilityIdentifier(confirmID)
        }
        .padding(AppSpacing.md)
        .background(
            AppColors.surfaceContainerLowest,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .shadowL1()
    }

    // MARK: — Cost / reward pill

    private func amountPill(prefix: String, value: Int, currency: Currency, tint: Bool) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: "\(prefix)\(value)")
                .font(AppTypography.numericSmall)
                .monospacedDigit()
                .foregroundStyle(AppColors.onSurface)
            CurrencyIcon(currency: currency, size: 16)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule().fill(tint ? currency.tint.opacity(0.14) : AppColors.surfaceContainerHigh)
        )
    }
}

// MARK: — Preview

#Preview {
    @Previewable @State var vm = ShopViewModel()
    ExchangePanel(viewModel: vm)
        .padding()
        .background(AppColors.background)
}
