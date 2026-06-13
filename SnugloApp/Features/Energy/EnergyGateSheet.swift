import SwiftUI

// MARK: — EnergyGateSheet
// Shown when a free player tries to start a paid game without enough energy.
// Offers: wait (live countdown), watch a rewarded ad for a refill, or go Premium
// for unlimited play. Auto-launches the pending game once energy is available.

struct EnergyGateSheet: View {

    @Environment(AppRouter.self) private var router

    /// Energy granted by one rewarded ad.
    private let adRefill = 10

    private var energy: EnergyStore { EnergyStore.shared }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle().fill(AppColors.tertiaryContainer)
                        .frame(width: 64, height: 64)
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.tertiary)
                }
                .padding(.top, AppSpacing.sm)

                Text("energy.out.title")
                    .font(AppTypography.headlineMedium)
                    .foregroundStyle(AppColors.onSurface)

                Text("energy.out.message")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Live energy + countdown to "enough to play".
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let cur = energy.refresh(now: ctx.date)
                    let secs = energy.secondsUntilPlayable(now: ctx.date)
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "bolt.fill").foregroundStyle(AppColors.tertiary)
                        Text(verbatim: "\(cur)/\(EnergyStore.maxEnergy)")
                            .font(AppTypography.numericLabel).monospacedDigit()
                            .foregroundStyle(AppColors.onSurface)
                        if secs > 0 {
                            Text(verbatim: "·  " + String(format: NSLocalizedString("energy.playable", comment: ""), Self.clock(secs)))
                                .font(AppTypography.bodyMedium).monospacedDigit()
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        }
                    }
                    .onChange(of: cur) { _, _ in if energy.canStartGame { launch() } }
                }

                VStack(spacing: AppSpacing.sm) {
                    // Watch a rewarded ad for an energy boost (if one is loaded).
                    if AdsManager.shared.rewardedReady {
                        Button {
                            AdsManager.shared.showRewarded {
                                EnergyStore.shared.addEnergy(adRefill)
                                RewardCenter.shared.showEnergy(adRefill)
                                launch()
                            }
                        } label: {
                            Text(verbatim: String(format: NSLocalizedString("energy.watchAd", comment: ""), adRefill))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GameButtonStyle(variant: .primary))
                        .foregroundStyle(AppColors.onPrimary)
                        .font(AppTypography.headlineSmall)
                    }

                    // Go Premium — unlimited play.
                    Button { dismiss(); router.showPaywall = true } label: {
                        Text("energy.goPremium").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GameButtonStyle(variant: .secondary))
                    .foregroundStyle(AppColors.softCocoa)
                    .font(AppTypography.headlineSmall)

                    Button("button.close") { dismiss() }
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .padding(.top, 2)
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 340)
            .background(AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL3()
            .padding(AppSpacing.lg)
        }
    }

    private func launch() {
        router.launchPendingGameIfReady()
    }

    private func dismiss() {
        router.showEnergyGate = false
        router.pendingGameRoute = nil
    }

    private static func clock(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
