import SwiftUI

// MARK: — PraiseBadge
// The cozy "Nicely done!" / "New Record!" flourish shown centred over the board
// on solve. Sits above all chrome (tray, HUD). A soft radial bloom + a gradient
// capsule with a sparkle, springing in with a gentle bob. Reduce-Motion safe.

struct PraiseBadge: View {
    let textKey: LocalizedStringKey

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Soft radial glow behind the badge so it reads over a busy board.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.tertiary.opacity(0.28), AppColors.tertiary.opacity(0)],
                        center: .center, startRadius: 0, endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(textKey)
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(.white)
                    .tracking(-0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.tertiary],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadowL3()
            .scaleEffect(appeared ? 1 : 0.6)
            .rotationEffect(.degrees(appeared ? 0 : -4))
        }
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                appeared = true
            }
        }
    }
}
