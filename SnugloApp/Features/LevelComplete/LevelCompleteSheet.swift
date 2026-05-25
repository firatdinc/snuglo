import SwiftUI

// MARK: — LevelCompleteSheet (Screen 08)
// Design reference: Designs/html/08-level-complete.html
//
// Presented as .fullScreenCover after the puzzle is solved.
// Confetti particles, ✓ badge, stat row (TIME / STARS / HINTS), Next Level / Replay / Home.

struct LevelCompleteSheet: View {

    let stats: LevelStats
    let onNextLevel: () -> Void
    let onReplay: () -> Void
    let onHome: () -> Void

    @State private var appear = false
    @State private var confettiOpacity: Double = 0

    private let confettiColors: [Color] = [
        AppColors.blockLavender, AppColors.blockSage, AppColors.blockPeach,
        AppColors.blockBlush, AppColors.blockCream, AppColors.blockDustyOlive
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // Confetti background
            confettiLayer

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // ✓ Badge
                checkBadge

                // Headline
                VStack(spacing: AppSpacing.sm) {
                    Text("Level Complete!")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)
                        .scaleEffect(appear ? 1 : 0.8)
                        .opacity(appear ? 1 : 0)
                }

                // Stats row
                statsRow
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                confettiOpacity = 1
            }
        }
    }

    // MARK: — Check badge

    private var checkBadge: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryContainer.opacity(0.3))
                .frame(width: 110, height: 110)
                .shadow(color: AppColors.primaryContainer.opacity(0.5), radius: 20, x: 0, y: 0)

            Circle()
                .fill(AppColors.primaryContainer)
                .frame(width: 84, height: 84)

            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(AppColors.primary)
        }
        .scaleEffect(appear ? 1 : 0.5)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05), value: appear)
    }

    // MARK: — Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                label: "TIME",
                value: formatTime(stats.elapsedSeconds),
                symbol: "timer"
            )

            Divider()
                .frame(height: 44)

            statCell(
                label: "STARS",
                value: String(repeating: "⭐", count: max(0, stats.stars)),
                symbol: nil
            )

            Divider()
                .frame(height: 44)

            statCell(
                label: "HINTS",
                value: "\(stats.hintsUsed)",
                symbol: "lightbulb"
            )
        }
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        .shadowL1()
        .padding(.horizontal, AppSpacing.lg)
    }

    private func statCell(label: String, value: String, symbol: String?) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)

            if let symbol {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: symbol)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.primary)
                    Text(value)
                        .font(AppTypography.numericLabel)
                        .foregroundStyle(AppColors.onSurface)
                }
            } else {
                Text(value.isEmpty ? "—" : value)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.onSurface)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Action buttons

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            // Next level — primary
            Button(action: onNextLevel) {
                HStack(spacing: AppSpacing.sm) {
                    Text("Next Level")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(AppColors.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                .shadowL1()
            }
            .buttonStyle(.plain)

            // Replay + Home — secondary row
            HStack(spacing: AppSpacing.sm) {
                Button(action: onReplay) {
                    Text("Replay")
                        .font(AppTypography.bodyLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .stroke(AppColors.outlineVariant, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onHome) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.outlineVariant, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: — Confetti

    private var confettiLayer: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<30, id: \.self) { i in
                    ConfettiDot(
                        color: confettiColors[i % confettiColors.count],
                        startX: CGFloat.random(in: 0...geo.size.width),
                        startY: CGFloat.random(in: -50...geo.size.height * 0.3),
                        duration: Double.random(in: 2.5...4.5),
                        delay: Double.random(in: 0...1.5)
                    )
                }
            }
        }
        .opacity(confettiOpacity)
        .allowsHitTesting(false)
    }

    // MARK: — Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: — Confetti dot particle

private struct ConfettiDot: View {
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let duration: Double
    let delay: Double

    @State private var y: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .position(x: startX, y: startY + y)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .easeIn(duration: duration)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
                ) {
                    y = 700
                    opacity = 0
                    rotation = Double.random(in: 180...720)
                }
            }
    }
}

// MARK: — Preview

#Preview {
    LevelCompleteSheet(
        stats: LevelStats(elapsedSeconds: 165, stars: 3, hintsUsed: 0),
        onNextLevel: {},
        onReplay: {},
        onHome: {}
    )
}
