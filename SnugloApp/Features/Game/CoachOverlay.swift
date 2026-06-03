import SwiftUI

// MARK: — CoachOverlay
// A one-time pulsing hand prompting the first drag on the very first level.
// Self-contained, single-palette, Reduce-Motion safe (no pulse).

struct CoachOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("coach.drag")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.surfaceContainerLowest, in: Capsule())
                .shadowL1()
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .offset(y: pulse ? -10 : 4)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("coach.drag"))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
