import SwiftUI

// MARK: — RewardModal
// One shared chrome for every reward popup (chest / spin / level-up / streak /
// calendar): a consistent scrim, spring entrance, optional confetti, and a
// standard primary button. Single-palette; Reduce-Motion safe.

struct RewardModal<Content: View>: View {
    var confetti: Bool = false
    var confettiIntensity: Double = 0.7
    /// Tap-on-scrim handler; nil disables tap-to-dismiss.
    var onScrimTap: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            AppColors.background.opacity(0.6).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onScrimTap?() }

            if confetti && !reduceMotion {
                SolveCelebration(intensity: confettiIntensity).allowsHitTesting(false)
            }

            VStack(spacing: AppSpacing.md, content: content)
                .padding(AppSpacing.xl)
                .scaleEffect(shown ? 1 : 0.92)
                .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.78)) {
                shown = true
            }
        }
    }
}

// MARK: — RewardTierFX
// Maps a reward's size to a celebration intensity so small rewards get a mini
// sparkle and jackpots/gems get full confetti.
enum RewardTierFX {
    static func intensity(coins: Int, gems: Int) -> Double {
        if gems > 0 || coins >= 300 { return 1.0 }   // jackpot / gems
        if coins >= 120 { return 0.6 }                // medium
        return 0.35                                    // small
    }
}

// MARK: — RewardButton
// The standard primary action for reward popups.
struct RewardButton: View {
    let titleKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.onPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.sm + 2)
                .background(AppColors.primary, in: Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }
}
