import SwiftUI

// MARK: — LevelUpOverlay
// Celebrates crossing into a new player level. Self-contained, single-palette,
// Reduce-Motion safe (no confetti, instant reveal).

struct LevelUpOverlay: View {
    let level: Int
    let coins: Int
    let onCollect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false

    var body: some View {
        RewardModal(confetti: true,
                    confettiIntensity: RewardTierFX.intensity(coins: coins, gems: 0),
                    onScrimTap: onCollect) {
            ZStack {
                Circle().fill(AppColors.primaryContainer.opacity(0.4)).frame(width: 132, height: 132)
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 84, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
            .scaleEffect(pop ? 1 : 0.6)

            Text("level.up")
                .font(AppTypography.labelSmall).tracking(0.8).textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
            Text(verbatim: String(format: NSLocalizedString("level.reached", comment: ""), level))
                .font(AppTypography.headlineLarge)
                .foregroundStyle(AppColors.onSurface)
            if coins > 0 {
                Text(verbatim: "🪙 +\(coins)")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
            }

            RewardButton(titleKey: "chest.collect", action: onCollect)
        }
        .onAppear {
            HapticService.shared.notify(.success)
            SoundService.shared.play(.levelUp)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.55)) { pop = true }
        }
    }
}
