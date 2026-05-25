import SwiftUI

// MARK: — PauseSheet
// Ref: Designs/html/07-pause-overlay.html
// Sheet content — dimmed overlay with Resume/Restart/Quit buttons.
// Sound/Haptics inline toggles via AppStorage.

struct PauseSheet: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundEnabled")   private var soundEnabled   = true
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
            Text("Paused")
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
                    Text("Resume")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onRestart()
                    dismiss()
                } label: {
                    Text("Restart")
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
                    Text("Home")
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
            HStack(spacing: AppSpacing.xl) {
                togglePill(label: "Sound", isOn: $soundEnabled,   icon: "speaker.wave.2.fill")
                togglePill(label: "Haptics", isOn: $hapticsEnabled, icon: "hand.tap.fill")
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

    private func togglePill(label: String, isOn: Binding<Bool>, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
            Label(label, systemImage: icon)
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
