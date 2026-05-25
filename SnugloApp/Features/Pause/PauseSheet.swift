import SwiftUI

// MARK: — PauseSheet (Screen 07)
// Design reference: Designs/html/07-pause-overlay.html
//
// Presented as .sheet over GameView.
// Resume / Restart / Quit to main menu.
// Shows frozen elapsed time.

struct PauseSheet: View {

    let elapsedSeconds: Int
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    // Settings toggles (UI placeholder — actual implementation Faz F)
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                handle

                // Title & time
                VStack(spacing: AppSpacing.sm) {
                    Text("Paused")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "timer")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        Text(formatTime(elapsedSeconds))
                            .font(AppTypography.numericLabel)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }

                Divider()
                    .padding(.horizontal, AppSpacing.lg)

                // Action buttons
                VStack(spacing: AppSpacing.sm) {
                    // Resume — primary
                    Button(action: onResume) {
                        Text("Resume")
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .shadowL1()

                    // Restart — outlined
                    Button(action: onRestart) {
                        Text("Restart")
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

                    // Quit — outlined / destructive tint
                    Button(action: onQuit) {
                        Text("Quit to Menu")
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
                .padding(.horizontal, AppSpacing.lg)

                Divider()
                    .padding(.horizontal, AppSpacing.lg)

                // Quick settings
                VStack(spacing: AppSpacing.sm) {
                    settingsRow(
                        title: "Sound",
                        symbol: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        isOn: $soundEnabled
                    )
                    settingsRow(
                        title: "Haptics",
                        symbol: hapticsEnabled ? "waveform" : "waveform.slash",
                        isOn: $hapticsEnabled
                    )
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            .padding(.top, AppSpacing.sm)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppRadius.card)
    }

    // MARK: — Sub-views

    private var handle: some View {
        Capsule()
            .fill(AppColors.outlineVariant)
            .frame(width: 36, height: 4)
    }

    private func settingsRow(title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        HStack {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppColors.surfaceContainerHigh)
                        .frame(width: 36, height: 36)
                    Image(systemName: symbol)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                }

                Text(title)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.onSurface)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
    }

    // MARK: — Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: — Preview

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PauseSheet(
                elapsedSeconds: 73,
                onResume: {},
                onRestart: {},
                onQuit: {}
            )
        }
}
