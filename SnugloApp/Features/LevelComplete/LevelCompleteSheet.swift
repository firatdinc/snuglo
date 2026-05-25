import SwiftUI

// MARK: — LevelCompleteSheet (v1.1: Stitch Nordic Hearth redesign · H-1: Localized)
// Ref: Designs/html/08-level-complete.html
// H-2: VoiceOver — stars row labelled, time formatted for speech, confetti hidden.
//
// v1.1 changes:
//   • Success circle background: blushAccent (#F5E6E0) — was primaryContainer
//   • Stat cell values: numericLabel (Space Grotesk 20pt) — was monospaced system
//   • Secondary buttons: softCocoa/secondary text + divider border (Stitch spec)

struct LevelCompleteSheet: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var stars: Int = 3
    var elapsedSeconds: Int = 165
    var hintsUsed: Int = 0
    var onNext: () -> Void   = {}
    var onReplay: () -> Void = {}

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // — Confetti placeholder — (hidden from VoiceOver; decorative)
            if !reduceMotion {
                confettiLayer
            }

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // — Check badge — (decorative; headline below conveys success)
                ZStack {
                    // Outer glow ring — blushAccent (#F5E6E0, Stitch Nordic Hearth)
                    Circle()
                        .fill(AppColors.blushAccent.opacity(0.6))
                        .frame(width: 112, height: 112)
                        .blur(radius: 8)

                    // Inner filled circle — blushAccent
                    Circle()
                        .fill(AppColors.blushAccent)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.5), lineWidth: 1.5)
                        )
                        .shadowL1()

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

                // — Headline —
                Text("complete.puzzleSolved")
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.onSurface)

                // — Stars — (H-2: combined label "2 of 3 stars earned")
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundStyle(i < stars ? AppColors.tertiary : AppColors.outlineVariant)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stars) of 3 stars earned")

                // — Stats row — (H-2: each cell gets speech-friendly label)
                HStack(spacing: 0) {
                    statCell(value: formattedTime, labelKey: "complete.time", a11yValue: formattedTimeSpeech)
                    Divider().frame(height: 40)
                    statCell(value: "\(stars)", labelKey: "complete.stars", a11yValue: "\(stars) stars")
                    Divider().frame(height: 40)
                    statCell(value: "\(hintsUsed)", labelKey: "complete.hints", a11yValue: "\(hintsUsed) hints used")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    AppColors.surfaceContainer,
                    in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                )
                .padding(.horizontal, AppSpacing.lg)
                // H-2: combine stats row into one VoiceOver read
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Solved in \(formattedTimeSpeech). \(stars) stars. \(hintsUsed) hints used.")

                Spacer()

                // — Buttons —
                VStack(spacing: AppSpacing.sm) {
                    Button {
                        onNext()
                        dismiss()
                    } label: {
                        Label("complete.next", systemImage: "arrow.right")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)
                    .accessibilityHint("Proceeds to the next level")
                    // Faz I-2: XCUITest identifier
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
                        // Faz I-2: XCUITest identifier
                        .accessibilityIdentifier("complete.continue")

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
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.bottom, AppSpacing.xl + AppSpacing.md)
            }
        }
    }

    // MARK: — Confetti placeholder (hidden from VoiceOver)

    private var confettiLayer: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(AppColors.blockPalette[i % AppColors.blockPalette.count].opacity(0.7))
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

    // MARK: — Stat cell

    private func statCell(value: String, labelKey: LocalizedStringKey, a11yValue: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
            Text(labelKey)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Helpers

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    /// H-2: Speech-friendly time string e.g. "1 minute 23 seconds"
    private var formattedTimeSpeech: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        if m > 0 {
            return "\(m) minute\(m == 1 ? "" : "s") \(s) second\(s == 1 ? "" : "s")"
        }
        return "\(s) second\(s == 1 ? "" : "s")"
    }
}

#Preview {
    LevelCompleteSheet(stars: 3, elapsedSeconds: 165, hintsUsed: 0)
        .environment(AppRouter())
}
