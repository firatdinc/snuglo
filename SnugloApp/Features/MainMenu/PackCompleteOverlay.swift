import SwiftUI

// MARK: — PackCompleteOverlay
// Celebrates finishing every level in a pack. Reuses the shared RewardModal
// (scrim + spring + confetti) + RewardButton. Single-palette, Reduce-Motion safe.

struct PackCompleteOverlay: View {
    let packTitle: String
    let coins: Int
    let gems: Int
    let onCollect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false

    var body: some View {
        RewardModal(confetti: true,
                    confettiIntensity: 1.0,
                    onScrimTap: onCollect) {
            ZStack {
                Circle().fill(AppColors.tertiary.opacity(0.35)).frame(width: 132, height: 132)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundStyle(AppColors.tertiary)
            }
            .scaleEffect(pop ? 1 : 0.6)

            Text("pack.complete.title")
                .font(AppTypography.labelSmall).tracking(0.8).textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
            Text(verbatim: packTitle)
                .font(AppTypography.headlineLarge)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)

            HStack(spacing: AppSpacing.md) {
                Text(verbatim: "🪙 +\(coins)")
                if gems > 0 { Text(verbatim: "💎 +\(gems)") }
            }
            .font(AppTypography.headlineSmall)
            .foregroundStyle(AppColors.onSurface)

            RewardButton(titleKey: "chest.collect", action: onCollect)
        }
        .onAppear {
            HapticService.shared.notify(.success)
            SoundService.shared.play(.reward)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.55)) { pop = true }
        }
    }
}
