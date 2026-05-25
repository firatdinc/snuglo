import SwiftUI

// MARK: — PauseOverlayView
// Ref: Designs/html/07-pause-overlay.html
// Presented as a full-screen overlay on top of GameView.
// Blurred dimmer + centered card with Resume / Restart / Home.

struct PauseOverlayView: View {

    let elapsedSeconds: Int
    let onResume:  () -> Void
    let onRestart: () -> Void
    let onHome:    () -> Void

    var body: some View {
        ZStack {
            // Dimmer
            Color(hex: "#3A332D")
                .opacity(0.30)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            // Card
            VStack(spacing: 0) {
                VStack(spacing: AppSpacing.sm) {
                    Text("Paused")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)

                    // Timer display
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "timer")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.secondary)
                        Text(formattedTime)
                            .font(AppTypography.numericLabel)
                            .foregroundStyle(AppColors.secondary)
                    }
                }
                .padding(.bottom, AppSpacing.xl)

                // Actions
                VStack(spacing: AppSpacing.md) {
                    // Resume — primary
                    actionButton(
                        icon: "play.fill", label: "Resume",
                        style: .primary,
                        action: onResume
                    )

                    // Restart — secondary
                    actionButton(
                        icon: "arrow.counterclockwise", label: "Restart",
                        style: .secondary,
                        action: onRestart
                    )

                    // Home — secondary
                    actionButton(
                        icon: "house", label: "Home",
                        style: .secondary,
                        action: onHome
                    )
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 320)
            .background(AppColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadowL2()
        }
    }

    // MARK: — Helpers

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private enum ButtonStyle { case primary, secondary }

    private func actionButton(icon: String, label: String,
                              style: ButtonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(AppTypography.headlineSmall)
            }
            .foregroundStyle(style == .primary ? AppColors.onPrimary : AppColors.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background {
                if style == .primary {
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .fill(AppColors.primary)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(.white.opacity(0.5))
                                .frame(height: 1)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                        }
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .fill(AppColors.surfaceContainerLowest)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .stroke(Color(hex: "#EDE6DA"), lineWidth: 1.5)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .shadowL1()
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        PauseOverlayView(
            elapsedSeconds: 73,
            onResume:  {},
            onRestart: {},
            onHome:    {}
        )
    }
}
