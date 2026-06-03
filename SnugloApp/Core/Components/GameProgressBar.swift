import SwiftUI

// MARK: — GameProgressBar
// A chunky, game-style progress bar: inset track, gradient fill with a glossy
// top sheen and rounded caps. Reads more "game" than a flat capsule. Single-palette.

struct GameProgressBar: View {
    /// 0…1.
    let progress: Double
    var height: CGFloat = 12
    var tint: Color = AppColors.primary

    var body: some View {
        GeometryReader { geo in
            let p = max(0, min(1, progress))
            ZStack(alignment: .leading) {
                // Inset track.
                Capsule()
                    .fill(AppColors.surfaceContainerHigh)
                    .overlay(Capsule().strokeBorder(AppColors.outlineVariant.opacity(0.4), lineWidth: 1))

                // Gradient fill + glossy sheen.
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.85), tint],
                                         startPoint: .leading, endPoint: .trailing))
                    .overlay(
                        Capsule()
                            .fill(LinearGradient(colors: [.white.opacity(0.3), .clear],
                                                 startPoint: .top, endPoint: .center))
                    )
                    .frame(width: max(p > 0 ? height : 0, geo.size.width * p))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: p)
            }
        }
        .frame(height: height)
    }
}
