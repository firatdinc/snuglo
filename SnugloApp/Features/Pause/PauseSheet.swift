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

            // — Actions — (v1.1: reusable PrimaryButton / SecondaryButton)
            VStack(spacing: AppSpacing.sm) {

                PrimaryButton("pause.resume", systemImage: "play.fill") {
                    onResume()
                    dismiss()
                }
                .accessibilityIdentifier("pause.resume")

                SecondaryButton("pause.restart", systemImage: "arrow.counterclockwise") {
                    onRestart()
                    dismiss()
                }

                SecondaryButton("pause.home", systemImage: "house") {
                    onQuit()
                    dismiss()
                }
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
