import SwiftUI

// MARK: — PowerUpBar
// 4 states per button:
//   .free     — free charge available (undo ×1, hint ×N) → primary style
//   .enabled  — gem spend available → primary style
//   .rewarded — undo only, no gems → primary style + ad icon, calls onUndoRewarded
//   .disabled — can't apply (no moves, no gems) → muted style

struct PowerUpBar: View {

    @Bindable var viewModel: GameViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onInsufficientGem: () -> Void
    var onUndoRewarded: () -> Void
    var onHintRewarded: () -> Void = {}

    private var wallet: WalletStore { .shared }
    private var progress: ProgressStore { .shared }

    // MARK: — Button state

    private enum BtnState { case free, enabled, rewarded, disabled }

    private func btnState(_ pu: PowerUp) -> BtnState {
        guard viewModel.canApply(pu) else { return .disabled }
        switch pu {
        case .undo:
            if viewModel.unlimitedUndo || viewModel.freeUndoAvailable { return .free }
            if wallet.canAfford(.gem, amount: pu.gemCost) { return .enabled }
            return .rewarded
        case .hint:
            if progress.hintCount > 0 { return .free }
            if wallet.canAfford(.gem, amount: pu.gemCost) { return .enabled }
            // Out of hints AND gems → offer a rewarded ad (if one is ready).
            return AdsManager.shared.rewardedReady ? .rewarded : .disabled
        case .shuffleTray:
            return wallet.canAfford(.gem, amount: pu.gemCost) ? .enabled : .disabled
        }
    }

    // MARK: — Body

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(PowerUp.allCases) { pu in
                powerUpButton(pu)
            }
        }
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Button rendering

    @ViewBuilder
    private func powerUpButton(_ pu: PowerUp) -> some View {
        let state = btnState(pu)
        let fg: Color = state == .disabled
            ? AppColors.onSurfaceVariant.opacity(0.6)
            : AppColors.onPrimary

        Button { handleTap(pu, state: state) } label: {
            HStack(spacing: 5) {
                Image(systemName: iconName(pu, state: state))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(fg)

                Text(pu.displayNameKey)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(fg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                badgeView(pu, state: state, fg: fg)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GameButtonStyle(
            variant: state == .disabled ? .muted : .primary,
            compact: true
        ))
        .disabled(state == .disabled)
        .accessibilityLabel(Text(pu.displayNameKey))
        .accessibilityIdentifier(accessibilityID(pu))
    }

    // MARK: — Icon

    private func iconName(_ pu: PowerUp, state: BtnState) -> String {
        if state == .rewarded && (pu == .undo || pu == .hint) { return "play.rectangle.fill" }
        return pu.sfSymbol
    }

    // MARK: — Badge (cost / free count / ad label)

    @ViewBuilder
    private func badgeView(_ pu: PowerUp, state: BtnState, fg: Color) -> some View {
        switch state {
        case .free:
            // Unlimited undo (relaxed modes) shows ∞ instead of a finite count.
            if pu == .undo && viewModel.unlimitedUndo {
                Text(verbatim: "∞")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(fg.opacity(0.85))
            } else {
                let count = pu == .hint ? progress.hintCount : 1
                Text(verbatim: "×\(count)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(fg.opacity(0.85))
            }

        case .enabled:
            HStack(spacing: 2) {
                CurrencyIcon(currency: .gem, size: 11)
                Text("\(pu.gemCost)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(fg.opacity(0.85))
                    .monospacedDigit()
            }

        case .rewarded:
            Text("powerup.free")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.onPrimary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(AppColors.tertiary, in: Capsule())

        case .disabled:
            HStack(spacing: 2) {
                CurrencyIcon(currency: .gem, size: 11)
                Text("\(pu.gemCost)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(fg)
                    .monospacedDigit()
            }
            .opacity(0.5)
        }
    }

    // MARK: — Tap handler

    private func handleTap(_ pu: PowerUp, state: BtnState) {
        if state == .rewarded {
            HapticService.shared.impact(.light)
            if pu == .hint { onHintRewarded() } else { onUndoRewarded() }
            return
        }
        let result = viewModel.applyPowerUp(pu)
        switch result {
        case .success:
            SoundService.shared.play(.place)
            HapticService.shared.impact(.light)
        case .insufficientGem:
            HapticService.shared.notify(.error)
            onInsufficientGem()
        case .notApplicable:
            HapticService.shared.notify(.error)
        }
    }

    // MARK: — Accessibility IDs

    private func accessibilityID(_ pu: PowerUp) -> String {
        switch pu {
        case .hint:        return "button.game.hint"
        case .undo:        return "button.powerup.undo"
        case .shuffleTray: return "button.powerup.shuffle"
        }
    }
}
