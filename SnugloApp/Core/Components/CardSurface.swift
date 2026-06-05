import SwiftUI

// MARK: — CardSurface
// Vibrant Play spec:
//   bg: white (surfaceContainerLowest)
//   radius: 20 pt (AppRadius.card)
//   elevation: L1 blue-tinted ambient shadow rgba(0,101,145,0.06) r=12 y=4

struct CardSurface: ViewModifier {

    func body(content: Content) -> some View {
        content
            // Front face of the tile.
            .background(
                AppColors.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            // Game-y "base lip": a warm slab sitting just below the face, so the
            // card reads as a physical raised tile (Toon Blast / Duolingo feel)
            // rather than a flat app panel. Same size, nudged down — only the
            // bottom edge + lower corners peek out beneath the face.
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.shadowAmbient.opacity(0.28))
                    .offset(y: 4)
            )
            // Defined warm border + top rim highlight in a SINGLE gradient stroke
            // (no .mask()/blend → no offscreen pass; cheap to render in long lists).
            // Bottom edge is darker/warmer so the lip and the stroke read as one
            // moulded edge.
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.65),
                                     AppColors.outlineVariant.opacity(0.5),
                                     AppColors.outline.opacity(0.45)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1.5
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
