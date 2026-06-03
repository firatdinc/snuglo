import SwiftUI

// MARK: — CardSurface
// Vibrant Play spec:
//   bg: white (surfaceContainerLowest)
//   radius: 20 pt (AppRadius.card)
//   elevation: L1 blue-tinted ambient shadow rgba(0,101,145,0.06) r=12 y=4

struct CardSurface: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(
                AppColors.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            // Soft top rim highlight + hairline border in a SINGLE gradient stroke
            // (no .mask()/blend → no offscreen pass; cheap to render in long lists).
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5),
                                     AppColors.outlineVariant.opacity(0.3),
                                     AppColors.outlineVariant.opacity(0.3)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadowL1()
    }
}

extension View {
    /// Applies card surface styling: white bg, radius 20, L1 ambient shadow.
    func cardSurface() -> some View {
        modifier(CardSurface())
    }

    /// Cohesive card: standard inner padding + card surface + optional accent ring.
    /// One call → consistent padding / radius / elevation across every card.
    func infoCard(accent: Color? = nil) -> some View {
        self
            .padding(AppSpacing.md)
            .cardSurface()
            .overlay(
                accent.map { c in
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .stroke(c.opacity(0.4), lineWidth: 1.5)
                }
            )
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
