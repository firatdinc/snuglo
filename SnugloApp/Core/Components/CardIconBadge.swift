import SwiftUI

// MARK: — CardIconBadge
// The standard leading icon badge for menu/reward cards: a 48pt rounded-square
// tinted fill + a 22pt semibold symbol. One component → consistent icon sizing,
// weight, corner radius and color discipline across the app.

struct CardIconBadge: View {
    let symbol: String
    var tint: Color = AppColors.primary
    var bg: Color = AppColors.primaryContainer
    var active: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bg.opacity(active ? 0.5 : 0.25))
                .frame(width: 48, height: 48)
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(active ? tint : AppColors.onSurfaceVariant)
        }
        .accessibilityHidden(true)
    }
}
