import SwiftUI

// MARK: — ExchangePanel

/// Two exchange rows: coin → gem (100:1) and gem → ticket (50:1).
/// Stepper lets the user pick how many units of the target currency to buy.
struct ExchangePanel: View {

    @Bindable var viewModel: ShopViewModel

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            coinToGemRow
            Divider()
                .background(AppColors.outlineVariant)
            gemToTicketRow
        }
        .padding(AppSpacing.md)
        .background(
            AppColors.surfaceContainerLowest,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .shadowL1()
    }

    // MARK: — Coin → Gem

    private var coinToGemRow: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                CurrencyIcon(currency: .coin, size: 18)
                    .accessibilityHidden(true)
                Text(verbatim: "\(viewModel.coinToGemAmount * CurrencyRate.coinPerGem)")
                    .font(AppTypography.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.onSurface)
                arrowIcon
                CurrencyIcon(currency: .gem, size: 18)
                    .accessibilityHidden(true)
                Text(verbatim: "\(viewModel.coinToGemAmount)")
                    .font(AppTypography.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.onSurface)
                Spacer(minLength: 0)
                Stepper("", value: $viewModel.coinToGemAmount, in: 1...10)
                    .labelsHidden()
                    .accessibilityIdentifier("shop.exchange.stepper.coin")
            }
            confirmButton(
                enabled: viewModel.canExchangeCoinToGem,
                id: "shop.exchange.confirm.coin",
                action: viewModel.exchangeCoinToGem
            )
        }
    }

    // MARK: — Gem → Ticket

    private var gemToTicketRow: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                CurrencyIcon(currency: .gem, size: 18)
                    .accessibilityHidden(true)
                Text(verbatim: "\(viewModel.gemToTicketAmount * CurrencyRate.gemPerTicket)")
                    .font(AppTypography.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.onSurface)
                arrowIcon
                CurrencyIcon(currency: .ticket, size: 18)
                    .accessibilityHidden(true)
                Text(verbatim: "\(viewModel.gemToTicketAmount)")
                    .font(AppTypography.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.onSurface)
                Spacer(minLength: 0)
                Stepper("", value: $viewModel.gemToTicketAmount, in: 1...5)
                    .labelsHidden()
                    .accessibilityIdentifier("shop.exchange.stepper.gem")
            }
            confirmButton(
                enabled: viewModel.canExchangeGemToTicket,
                id: "shop.exchange.confirm.gem",
                action: viewModel.exchangeGemToTicket
            )
        }
    }

    // MARK: — Shared helpers

    private var arrowIcon: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12))
            .foregroundStyle(AppColors.onSurfaceVariant)
            .accessibilityHidden(true)
    }

    private func confirmButton(enabled: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("shop.exchange.confirm")
                .font(AppTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(enabled ? .white : AppColors.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xs + 2)
                .background(
                    enabled ? AnyShapeStyle(AppColors.primary) : AnyShapeStyle(AppColors.surfaceContainerHigh),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityIdentifier(id)
    }
}

// MARK: — Preview

#Preview {
    @Previewable @State var vm = ShopViewModel()
    ExchangePanel(viewModel: vm)
        .padding()
        .background(AppColors.background)
}
