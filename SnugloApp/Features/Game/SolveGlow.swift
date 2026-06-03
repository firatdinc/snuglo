import SwiftUI

// MARK: — SolveGlow
// A single soft, cozy bloom that blooms out over the board when a level is solved
// — the calm replacement for confetti (confetti is reserved for reward moments).
// Reduce-Motion safe (renders nothing static-jarring).

struct SolveGlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColors.tertiary.opacity(0.30), AppColors.tertiary.opacity(0)],
                    center: .center, startRadius: 0, endRadius: 240
                )
            )
            .scaleEffect(animate ? 1.5 : 0.35)
            .opacity(animate ? 0 : 0.85)
            .allowsHitTesting(false)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.95)) { animate = true }
            }
    }
}
