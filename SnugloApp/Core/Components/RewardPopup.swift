import SwiftUI

// MARK: — RewardPopup
// Centred, animated reward celebration (Worplix-style): a rounded card springs
// in over a dim scrim with a glowing icon, rotating sunburst, and a big "+N".
// Auto-dismisses; tap anywhere to dismiss early. Reduce-Motion safe.

struct RewardPopup: View {

    let reward: RewardCenter.Reward
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var spin = false

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.55 : 0).ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    // Rotating sunburst behind the icon.
                    if !reduceMotion {
                        Image(systemName: "sparkle")
                            .font(.system(size: 130, weight: .thin))
                            .foregroundStyle(reward.tint.opacity(0.18))
                            .rotationEffect(.degrees(spin ? 360 : 0))
                    }
                    Circle()
                        .fill(reward.tint.opacity(0.16))
                        .frame(width: 92, height: 92)
                    icon(size: 52)
                        .shadow(color: reward.tint.opacity(0.5), radius: 12)
                }
                .frame(height: 130)

                Text("reward.earned")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)

                HStack(spacing: AppSpacing.xs) {
                    Text(verbatim: "+\(reward.amount)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColors.onSurface)
                        .monospacedDigit()
                    icon(size: 34)
                }

                Button("reward.great") { close() }
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primary, in: Capsule())
                    .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 320)
            .background(AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL3()
            .padding(AppSpacing.lg)
            .scaleEffect(shown ? 1 : 0.6)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            HapticService.shared.notify(.success)
            SoundService.shared.play(.reward)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                shown = true
            }
            if !reduceMotion {
                withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { spin = true }
            }
            // Auto-dismiss after a beat.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.6))
                close()
            }
        }
    }

    /// Currency rewards use the illustrated asset; energy etc. fall back to SF.
    @ViewBuilder
    private func icon(size: CGFloat) -> some View {
        if let asset = reward.assetName {
            Image(asset)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: reward.systemImage)
                .font(.system(size: size * 0.82, weight: .bold))
                .foregroundStyle(reward.tint)
        }
    }

    private func close() {
        guard shown else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { shown = false }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 200))
            onDismiss()
        }
    }
}
