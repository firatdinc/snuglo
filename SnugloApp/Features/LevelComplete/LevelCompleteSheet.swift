import SwiftUI

// MARK: — LevelCompleteSheet (Faz 3b: Vibrant Play restyle)
// Ref: Designs/VibrantPlay/level-complete.png
// H-2: VoiceOver — stats container has combined label; confetti hidden; mascot hidden.
//
// Faz 3b changes:
//   • Hero: mascot-tiger in gold gradient ring + badge-trophy overlay (was SF Symbol check)
//   • Stats: pill cards (surfaceContainerLowest + shadowL1) replacing divider grid
//   • Buttons: PrimaryButton next + outline replay/home (identifiers preserved verbatim)

struct LevelCompleteSheet: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var stars: Int = 3
    var elapsedSeconds: Int = 165
    var hintsUsed: Int = 0
    var moveCount: Int = 0
    var bestTimeSeconds: Int?
    var earnedReward: [Currency: Int] = [:]
    /// Multi-level daily challenge. When `isDaily`, the sheet shows the daily
    /// progress ("N/5") and — on the LAST level of the day — a celebratory
    /// "all done" headline plus a Home primary button (the card then locks
    /// until tomorrow). On earlier daily levels the primary button advances to
    /// the next daily level. The redundant secondary Home button is hidden.
    var isDaily: Bool = false
    var dailyIndex: Int? = nil      // 0-based index of the daily level just solved
    var dailyTotal: Int  = ProgressStore.dailyLevelCount
    var onNext: () -> Void   = {}
    var onReplay: () -> Void = {}

    /// True when the just-solved level was the final daily level of the day.
    private var isLastDaily: Bool {
        guard isDaily, let idx = dailyIndex else { return false }
        return idx + 1 >= dailyTotal
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // Confetti — decorative; hidden from VoiceOver
            if !reduceMotion {
                confettiLayer
            }

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                heroView

                VStack(spacing: AppSpacing.sm) {
                    Text(isLastDaily ? "complete.dailyAllDone" : "complete.puzzleSolved")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)
                        .multilineTextAlignment(.center)

                    // Daily progress chip — "N/5" so the player sees where they are.
                    if isDaily {
                        Text(verbatim: "\((dailyIndex ?? 0) + 1)/\(dailyTotal)")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, AppSpacing.sm + 2)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primaryContainer.opacity(0.9), in: Capsule())

                        if isLastDaily {
                            Text("complete.dailyComeBack")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.lg)
                        }
                    }

                    // Stars row — H-2: combined label
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<3, id: \.self) { starIdx in
                            Image(systemName: starIdx < stars ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundStyle(starIdx < stars ? AppColors.tertiary : AppColors.outlineVariant)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(stars) of 3 stars earned")
                }

                // Stat pills — H-2: combined label on container
                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        statPill(value: formattedTime, labelKey: "complete.time")
                        statPill(value: "\(stars)/3", labelKey: "complete.stars")
                        statPill(value: "\(hintsUsed)", labelKey: "complete.hints")
                    }
                    HStack(spacing: AppSpacing.sm) {
                        statPill(value: "\(moveCount)", labelKey: "complete.moves")
                        statPill(value: formattedBestTime, labelKey: "complete.bestTime")
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Solved in \(formattedTimeSpeech). \(stars) stars. \(hintsUsed) hints used." +
                    " \(moveCount) moves. Best time \(formattedBestTime)."
                )

                rewardRow

                Spacer()

                VStack(spacing: AppSpacing.sm) {
                    // Last daily level → Home; otherwise advance (pack next / next daily).
                    PrimaryButton(
                        isLastDaily ? "complete.home" : "complete.next",
                        systemImage: isLastDaily ? "house.fill" : "arrow.right"
                    ) {
                        onNext()
                        dismiss()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .accessibilityHint(isLastDaily ? "Returns to the main menu" : "Proceeds to the next level")
                    .accessibilityIdentifier("complete.next")

                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            onReplay()
                            dismiss()
                        } label: {
                            Text("complete.replay")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                        .stroke(AppColors.primary, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Restarts this same level")
                        .accessibilityIdentifier("complete.continue")

                        // Hidden only on the last daily level — there the primary
                        // button already goes Home, so a second Home is redundant.
                        if !isLastDaily {
                            Button {
                                dismiss()
                                router.popToRoot()
                            } label: {
                                Text("complete.home")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundStyle(AppColors.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm + 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                            .stroke(AppColors.outlineVariant, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Returns to the main menu")
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.bottom, AppSpacing.xl + AppSpacing.md)
            }
        }
    }

    // MARK: — Reward row

    @ViewBuilder
    private var rewardRow: some View {
        if !earnedReward.isEmpty {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.tertiary)
                    .accessibilityHidden(true)
                Text("levelcomplete.reward")
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                Spacer()
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Currency.allCases.filter { earnedReward[$0] != nil }) { currency in
                        if let amount = earnedReward[currency] {
                            HStack(spacing: 3) {
                                Image(systemName: currency.sfSymbol)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(currency.tint)
                                    .accessibilityHidden(true)
                                Text("+\(amount)")
                                    .font(AppTypography.numericSmall)
                                    .foregroundStyle(currency.tint)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm + 2)
            .padding(.horizontal, AppSpacing.md)
            .background(AppColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.4), lineWidth: 1)
            )
            .shadowL1()
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: — Hero (mascot-tiger in gold ring + badge-trophy overlay)

    private var heroView: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                // Radial gold glow behind the ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.tertiary.opacity(0.45), AppColors.tertiary.opacity(0)],
                            center: .center,
                            startRadius: 44,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Gold stroke ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppColors.tertiary, AppColors.tertiary.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 116, height: 116)

                Image("mascot-tiger")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            }

            Image("badge-trophy")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .offset(x: -10, y: -6)
        }
        .accessibilityHidden(true)
    }

    // MARK: — Confetti placeholder (decorative)

    private var confettiLayer: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { confettiIdx in
                Circle()
                    .fill(AppColors.blockPalette[confettiIdx % AppColors.blockPalette.count].opacity(0.7))
                    .frame(width: CGFloat.random(in: 6...14))
                    .offset(
                        x: CGFloat.random(in: -160...160),
                        y: CGFloat.random(in: -300...300)
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: — Stat pill

    private func statPill(value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.primary)
            Text(labelKey)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.4), lineWidth: 1)
        )
        .shadowL1()
    }

    // MARK: — Helpers

    private var formattedTime: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var formattedBestTime: String {
        guard let totalSecs = bestTimeSeconds else { return "—" }
        let mins = totalSecs / 60
        let secs = totalSecs % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// H-2: Speech-friendly time string e.g. "1 minute 23 seconds"
    private var formattedTimeSpeech: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        if mins > 0 {
            return "\(mins) minute\(mins == 1 ? "" : "s") \(secs) second\(secs == 1 ? "" : "s")"
        }
        return "\(secs) second\(secs == 1 ? "" : "s")"
    }
}

#Preview {
    LevelCompleteSheet(stars: 3, elapsedSeconds: 165, hintsUsed: 0, moveCount: 12, bestTimeSeconds: 143)
        .environment(AppRouter())
}
