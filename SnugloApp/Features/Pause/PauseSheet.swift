import SwiftUI

// MARK: — PauseSheet (v1.1: Stitch Nordic Hearth redesign)
// Ref: Designs/html/07-pause-overlay.html · Stitch screenshot: pause.png
//
// v1.1 changes:
//   • Removed quick-toggle pills (sound/haptics) — available in full SettingsView.
//   • Primary CTA "Resume" uses AppColors.primary (dark lavender) + onPrimary (white).
//   • Secondary buttons use divider border + softCocoa text (Stitch secondary spec).
//   • Timer display uses AppTypography.numericLabel (Space Grotesk medium).
//   • Compact centered-card look matching the Stitch pause screenshot.
//   • onResume/onRestart callbacks: timer is now restarted via GameView's .onDismiss.

struct PauseSheet: View {

    @Environment(\.dismiss) private var dismiss

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
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .accessibilityHidden(true)
                Text(formattedTime)
                    .font(AppTypography.numericLabel)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            // — Actions —
            VStack(spacing: AppSpacing.sm) {

                // Primary: Resume
                Button {
                    onResume()
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("pause.resume")
                            .font(AppTypography.headlineSmall)
                    }
                    .foregroundStyle(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
                // Scale press animation (Stitch spec: press → scale 0.98)
                .buttonRepeatBehavior(.disabled)
                // Faz I-2: XCUITest lookup
                .accessibilityIdentifier("pause.resume")

                // Secondary: Restart
                Button {
                    onRestart()
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("pause.restart")
                            .font(AppTypography.headlineSmall)
                    }
                    .foregroundStyle(AppColors.softCocoa)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.divider, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)

                // Secondary: Home
                Button {
                    onQuit()
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "house")
                            .font(.system(size: 14))
                        Text("pause.home")
                            .font(AppTypography.headlineSmall)
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppColors.divider, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                // Faz I-2: XCUITest identifier
                .accessibilityIdentifier("pause.quit")
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
}

#Preview {
    Text("Game underneath")
        .sheet(isPresented: .constant(true)) {
            PauseSheet(elapsedSeconds: 73)
        }
}
