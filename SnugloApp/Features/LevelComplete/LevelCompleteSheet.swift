import SwiftUI

// MARK: — LevelCompleteSheet
// Ref: Designs/html/08-level-complete.html
// Full-screen cover shown when puzzle is solved.
// Star count, time display, confetti placeholder, Next/Replay/Home buttons.

struct LevelCompleteSheet: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var stars: Int = 3
    var elapsedSeconds: Int = 165
    var hintsUsed: Int = 0
    var onNext: () -> Void   = {}
    var onReplay: () -> Void = {}

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // — Confetti placeholder —
            confettiLayer

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // — Check badge —
                ZStack {
                    Circle()
                        .fill(AppColors.primaryContainer.opacity(0.4))
                        .frame(width: 112, height: 112)
                        .blur(radius: 8)

                    Circle()
                        .fill(AppColors.primaryContainer)
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

                // — Headline —
                Text("Level complete!")
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.onSurface)

                // — Stars —
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundStyle(i < stars ? AppColors.tertiary : AppColors.outlineVariant)
                    }
                }

                // — Stats row —
                HStack(spacing: 0) {
                    statCell(value: formattedTime, label: "TIME")
                    Divider().frame(height: 40)
                    statCell(value: "\(stars)", label: "STARS")
                    Divider().frame(height: 40)
                    statCell(value: "\(hintsUsed)", label: "HINTS")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    AppColors.surfaceContainer,
                    in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                )
                .padding(.horizontal, AppSpacing.lg)

                Spacer()

                // — Buttons —
                VStack(spacing: AppSpacing.sm) {
                    Button {
                        onNext()
                        dismiss()
                    } label: {
                        Label("Next Level", systemImage: "arrow.right")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)

                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            onReplay()
                            dismiss()
                        } label: {
                            Text("Replay")
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

                        Button {
                            dismiss()
                            router.popToRoot()
                        } label: {
                            Text("Home")
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
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                .padding(.bottom, AppSpacing.xl + AppSpacing.md)
            }
        }
    }

    // MARK: — Confetti placeholder

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
    }

    // MARK: — Stat cell

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundStyle(AppColors.onSurface)
            Text(label)
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
}

#Preview {
    LevelCompleteSheet(stars: 3, elapsedSeconds: 165, hintsUsed: 0)
        .environment(AppRouter())
}
