import SwiftUI

// MARK: — StreakMilestoneOverlay
// Celebrates reaching a play-streak milestone (7/14/30…). Self-contained,
// single-palette, Reduce-Motion safe.

struct StreakMilestoneOverlay: View {
    let days: Int
    let coins: Int
    let gems: Int
    let onCollect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false

    var body: some View {
        RewardModal(confetti: true,
                    confettiIntensity: RewardTierFX.intensity(coins: coins, gems: gems),
                    onScrimTap: onCollect) {
            ZStack {
                Circle().fill(AppColors.tertiary.opacity(0.22)).frame(width: 132, height: 132)
                Image(systemName: "flame.fill")
                    .font(.system(size: 78, weight: .semibold))
                    .foregroundStyle(AppColors.tertiary)
            }
            .scaleEffect(pop ? 1 : 0.6)

            Text(verbatim: String(format: NSLocalizedString("streak.milestone", comment: ""), days))
                .font(AppTypography.headlineLarge)
                .foregroundStyle(AppColors.onSurface)
            Text("streak.keepGoing")
                .font(AppTypography.labelSmall).tracking(0.6).textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)

            Text(verbatim: gems > 0 ? "🪙 +\(coins)   💎 +\(gems)" : "🪙 +\(coins)")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            RewardButton(titleKey: "chest.collect", action: onCollect)
        }
        .onAppear {
            HapticService.shared.notify(.success)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.55)) { pop = true }
        }
    }
}
