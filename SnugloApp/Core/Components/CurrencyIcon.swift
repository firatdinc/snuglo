import SwiftUI

// MARK: — CurrencyIcon
// Square icon sized to `size` pt.
// Uses Currency.sfSymbol (SF Symbol) and Currency.tint (AppColors token).
// VoiceOver: labelled with the localized currency display name.

struct CurrencyIcon: View {

    let currency: Currency
    let size: CGFloat

    init(currency: Currency, size: CGFloat = 24) {
        self.currency = currency
        self.size = size
    }

    var body: some View {
        Image(systemName: currency.sfSymbol)
            .font(.system(size: size * 0.7, weight: .semibold))
            .foregroundStyle(currency.tint)
            .frame(width: size, height: size)
            .accessibilityLabel(Text(LocalizedStringKey(currency.displayNameKey)))
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 16) {
        ForEach(Currency.allCases) { currency in
            VStack(spacing: 4) {
                CurrencyIcon(currency: currency, size: 32)
                Text(currency.rawValue)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
        }
    }
    .padding()
}
