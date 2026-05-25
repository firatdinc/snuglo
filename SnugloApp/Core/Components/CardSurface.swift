import SwiftUI

// MARK: — CardSurface
// Stitch Nordic Hearth spec:
//   bg: white (surfaceContainerLowest)
//   radius: 20 pt (AppRadius.card)
//   elevation: L1 ambient shadow rgba(58,51,45,0.06) r=12 y=4

struct CardSurface: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(
                AppColors.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            )
            .shadowL1()
    }
}

extension View {
    /// Applies card surface styling: white bg, radius 20, L1 ambient shadow.
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 16) {
        Text("Card Content")
            .font(.body)
            .padding(24)
            .cardSurface()
    }
    .padding(24)
    .background(Color(UIColor.systemGroupedBackground))
}
