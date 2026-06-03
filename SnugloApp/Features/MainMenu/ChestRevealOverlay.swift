import SwiftUI

// MARK: — ChestRevealOverlay
// The juicy chest-opening moment, redesigned for a satisfying payoff:
//   1. Anticipation  — the (solid, opaque) chest shakes with building intensity.
//   2. Burst         — a white flash + reward sound + strong haptic at the pop.
//   3. Reveal        — rotating golden light rays bloom behind a reward that
//                      springs in with an overshoot, plus a particle burst.
// Self-contained; single-palette; Reduce-Motion safe (skips motion, shows result).

struct ChestRevealOverlay: View {
    let reward: ChestReward
    let onCollect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var adShown = false
    @State private var shake: CGFloat = 0      // anticipation rotation
    @State private var pulse: CGFloat = 1      // anticipation scale
    @State private var flash = false           // burst flash
    @State private var rewardScale: CGFloat = 0
    @State private var rayAngle: Double = 0

    private var tierColor: Color {
        switch reward.tier {
        case .common: return AppColors.primary
        case .rare:   return AppColors.tertiary
        case .epic:   return AppColors.blockLavender
        }
    }

    var body: some View {
        ZStack {
            // Opaque scrim for focus (was too transparent before).
            AppColors.background.opacity(0.92).ignoresSafeArea()
                .onTapGesture { if revealed { onCollect() } }

            if revealed && !reduceMotion {
                SolveCelebration(intensity: RewardTierFX.intensity(coins: reward.coin, gems: reward.gem))
                    .allowsHitTesting(false)
            }

            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    // Rotating sunburst light rays behind the reward.
                    if revealed {
                        sunburst
                            .frame(width: 320, height: 320)
                            .rotationEffect(.degrees(rayAngle))
                            .opacity(0.9)
                            .blendMode(.plusLighter)
                            .allowsHitTesting(false)
                    }

                    // Solid chest / reward medallion.
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [tierColor.opacity(0.9), tierColor.opacity(0.55)],
                                    center: .center, startRadius: 8, endRadius: 90
                                )
                            )
                            .frame(width: 168, height: 168)
                            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 2))
                            .shadow(color: tierColor.opacity(0.6), radius: revealed ? 34 : 14, y: 6)

                        Image(systemName: revealed ? "gift.fill" : "shippingbox.fill")
                            .font(.system(size: 78, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                            .rotationEffect(.degrees(revealed ? 0 : Double(shake)))
                            .scaleEffect(revealed ? rewardScale : pulse)
                    }

                    // White burst flash at the moment of opening.
                    if flash {
                        Circle()
                            .fill(.white)
                            .frame(width: 220, height: 220)
                            .blur(radius: 6)
                            .transition(.scale(scale: 1.6).combined(with: .opacity))
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 320)

                if revealed {
                    VStack(spacing: AppSpacing.xs) {
                        Text(verbatim: reward.gem > 0 ? "💎 +\(reward.gem)" : "🪙 +\(reward.coin)")
                            .font(AppTypography.headlineLarge)
                            .foregroundStyle(AppColors.onSurface)
                        Text("chest.reward")
                            .font(AppTypography.labelSmall)
                            .tracking(0.6)
                            .textCase(.uppercase)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .transition(.scale.combined(with: .opacity))

                    if !adShown {
                        Button {
                            adShown = true
                            AdsManager.shared.showRewarded {
                                if reward.coin > 0 { WalletStore.shared.earn(.coin, amount: reward.coin) }
                                if reward.gem > 0 { WalletStore.shared.earn(.gem, amount: reward.gem) }
                                HapticService.shared.notify(.success)
                                onCollect()
                            }
                        } label: {
                            Label("reward.double", systemImage: "play.rectangle.fill")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, AppSpacing.sm)
                                .overlay(Capsule().stroke(AppColors.primary, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                    RewardButton(titleKey: "chest.collect", action: onCollect)
                        .accessibilityIdentifier("chest.collect")
                }
            }
            .padding(AppSpacing.xl)
        }
        .onAppear { runSequence() }
    }

    // MARK: — Sunburst rays

    private var sunburst: some View {
        let count = 16
        let stops: [Gradient.Stop] = (0..<count * 2).map { i in
            Gradient.Stop(
                color: i % 2 == 0 ? tierColor.opacity(0.55) : .clear,
                location: Double(i) / Double(count * 2)
            )
        }
        return Circle()
            .fill(AngularGradient(gradient: Gradient(stops: stops), center: .center))
            .mask(
                RadialGradient(
                    colors: [.white, .white.opacity(0.05)],
                    center: .center, startRadius: 30, endRadius: 160
                )
            )
    }

    // MARK: — Animation sequence

    private func runSequence() {
        guard !reduceMotion else {
            revealed = true
            rewardScale = 1
            return
        }
        // 1. Anticipation — shake builds, with a subtle scale pulse + light ticks.
        withAnimation(.easeInOut(duration: 0.09).repeatCount(9, autoreverses: true)) { shake = 9 }
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { pulse = 1.08 }
        HapticService.shared.prepareImpact()
        for i in 0..<3 {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(220 * (i + 1)))
                HapticService.shared.impact(.light)
            }
        }
        // 2. Burst + 3. Reveal at ~0.9s.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            SoundService.shared.play(.reward)
            HapticService.shared.notify(.success)
            withAnimation(.easeOut(duration: 0.18)) { flash = true }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { rayAngle = 360 }
            revealed = true
            // Reward springs in with an overshoot, then settles.
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { rewardScale = 1 }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeOut(duration: 0.25)) { flash = false }
        }
    }
}
