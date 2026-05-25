import SwiftUI

// MARK: — PauseSheet (H-1: Localized)
// Ref: Designs/html/07-pause-overlay.html
// Sheet content — dimmed overlay with Resume/Restart/Quit buttons.
// Toggles write to the same @AppStorage keys as SettingsView/SoundService/HapticService
// so changes take effect immediately and are read by in-game playback.

struct PauseSheet: View {

    @Environment(\.dismiss) private var dismiss

    // Must match keys read by SoundService ("sfxEnabled") and HapticService ("hapticsEnabled").
    @AppStorage("sfxEnabled")     private var sfxEnabled     = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var onResume: () -> Void  = {}
    var onRestart: () -> Void = {}
    var onQuit: () -> Void    = {}

    var elapsedSeconds: Int = 73   // placeholder

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // — Handle —
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColors.outlineVariant)
                .frame(width: 40, height: 5)
                .padding(.top, AppSpacing.sm)

            // — Title —
            Text("pause.title")
                .font(AppTypography.headlineLarge)
                .tracking(-0.6)
                .foregroundStyle(AppColors.onSurface)

            // — Timer —
            Text(formattedTime)
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .foregroundStyle(AppColors.onSurfaceVariant)

            // — Actions —
            VStack(spacing: AppSpacing.sm) {
                Button {
                    onResume()
                    dismiss()
                } label: {
                    Text("pause.resume")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
                // Faz I-2: XCUITest lookup — app.buttons["pause.resume"]
                // Text("pause.resume") is a LocalizedStringKey → accessibility label becomes
                // locale-dependent ("Devam Et", "Continuar") so identifier must be explicit.
                .accessibilityIdentifier("pause.resume")

                Button {
                    onRestart()
                    dismiss()
                } label: {
                    Text("pause.restart")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .stroke(AppColors.primary, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    onQuit()
                    dismiss()
                } label: {
                    Text("pause.home")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .stroke(AppColors.outlineVariant, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.horizontal, AppSpacing.xs)

            // — Quick toggles —
            // Bound to the same singletons as SettingsView — changes are
            // instantly reflected everywhere and persisted to UserDefaults.
            HStack(spacing: AppSpacing.xl) {
                togglePill(labelKey: "pause.sound", isOn: $sfxEnabled, icon: "speaker.wave.2.fill")
                togglePill(labelKey: "pause.haptics", isOn: $hapticsEnabled, icon: "hand.tap.fill")
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(AppColors.surface)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    // MARK: — Helpers

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func togglePill(labelKey: LocalizedStringKey, isOn: Binding<Bool>, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
            Label(labelKey, systemImage: icon)
                .font(AppTypography.labelSmall)
                .tracking(0.3)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }
}

#Preview {
    Text("Game underneath")
        .sheet(isPresented: .constant(true)) {
            PauseSheet(elapsedSeconds: 73)
        }
}
