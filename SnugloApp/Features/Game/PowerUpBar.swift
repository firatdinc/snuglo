import SwiftUI

// MARK: — PowerUpBar
// Horizontal row of 3 power-up buttons: hint, undo, shuffleTray.
// Reads GameViewModel + WalletStore + ProgressStore for enabled state.
// Calls viewModel.applyPowerUp; reports .insufficientGem via callback.

struct PowerUpBar: View {

    @Bindable var viewModel: GameViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onInsufficientGem: () -> Void

    private var wallet: WalletStore { .shared }
    private var progress: ProgressStore { .shared }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(PowerUp.allCases) { pu in
                powerUpButton(pu)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Single button

    @ViewBuilder
    private func powerUpButton(_ pu: PowerUp) -> some View {
        let enabled = isEnabled(pu)
        Button {
            handleTap(pu)
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: pu.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.onPrimary)

                Text(pu.displayNameKey)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                costLabel(pu)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(GameButtonStyle(variant: .primary))
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
        .accessibilityLabel(Text(pu.displayNameKey))
        .accessibilityIdentifier(accessibilityID(pu))
    }

    // MARK: — Cost label

    @ViewBuilder
    private func costLabel(_ pu: PowerUp) -> some View {
        if pu == .hint && progress.hintCount > 0 {
            // Free hint available — show inventory count
            Text("×\(progress.hintCount)")
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.onPrimary.opacity(0.85))
        } else {
            HStack(spacing: 2) {
                CurrencyIcon(currency: .gem, size: 11)
                Text("\(pu.gemCost)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onPrimary.opacity(0.85))
                    .monospacedDigit()
            }
        }
    }

    // MARK: — State helpers

    private func isEnabled(_ pu: PowerUp) -> Bool {
        guard viewModel.canApply(pu) else { return false }
        if pu == .hint {
            return progress.hintCount > 0 || wallet.canAfford(.gem, amount: pu.gemCost)
        }
        return wallet.canAfford(.gem, amount: pu.gemCost)
    }

    private func accessibilityID(_ pu: PowerUp) -> String {
        switch pu {
        case .hint:        return "button.game.hint"
        case .undo:        return "button.powerup.undo"
        case .shuffleTray: return "button.powerup.shuffle"
        }
    }

    // MARK: — Tap handler

    private func handleTap(_ pu: PowerUp) {
        let result = viewModel.applyPowerUp(pu)
        switch result {
        case .success:
            let anim: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
            withAnimation(anim) {}
            SoundService.shared.play(.place)
            HapticService.shared.impact(.light)
        case .insufficientGem:
            HapticService.shared.notify(.error)
            onInsufficientGem()
        case .notApplicable:
            HapticService.shared.notify(.error)
        }
    }
}
