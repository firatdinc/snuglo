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

    // Quick in-game toggles (mirror the main Settings keys).
    @AppStorage("musicEnabled")   private var musicEnabled   = true
    @AppStorage("sfxEnabled")     private var sfxEnabled     = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var onResume: () -> Void   = {}
    var onRestart: () -> Void  = {}
    var onQuit: () -> Void     = {}
    var onHint: () -> Void     = {}
    var onSettings: () -> Void = {}

    /// Hint button is hidden when no hints remain (or unsupported, e.g. Endless).
    var hintsAvailable: Bool = true

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

            // — Quick toggles — music / sfx / haptics, adjustable mid-game.
            HStack(spacing: AppSpacing.md) {
                quickToggle(isOn: $musicEnabled, on: "music.note", off: "music.note", label: "settings.sound.music")
                quickToggle(isOn: $sfxEnabled, on: "speaker.wave.2.fill", off: "speaker.slash.fill", label: "settings.sound.effects")
                quickToggle(isOn: $hapticsEnabled, on: "hand.tap.fill", off: "hand.tap", label: "settings.haptics.enable")
            }

            // — Actions — (v1.1: reusable PrimaryButton / SecondaryButton)
            VStack(spacing: AppSpacing.sm) {

                PrimaryButton("pause.resume", systemImage: "play.fill") {
                    onResume()
                    dismiss()
                }
                .accessibilityIdentifier("pause.resume")

                if hintsAvailable {
                    SecondaryButton("pause.hint", systemImage: "lightbulb.fill") {
                        onHint()
                        dismiss()
                    }
                    .accessibilityIdentifier("pause.hint")
                }

                SecondaryButton("pause.restart", systemImage: "arrow.counterclockwise") {
                    onRestart()
                    dismiss()
                }

                SecondaryButton("pause.settings", systemImage: "gearshape.fill") {
                    dismiss()
                    onSettings()
                }
                .accessibilityIdentifier("pause.settings")

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
        .presentationDetents([.fraction(0.62), .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: — Quick toggle chip

    @ViewBuilder
    private func quickToggle(isOn: Binding<Bool>, on: String, off: String, label: LocalizedStringKey) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            if label == "settings.sound.music" { MusicService.shared.refresh() }
            HapticService.shared.impact(.light)
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: isOn.wrappedValue ? on : off)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isOn.wrappedValue ? AppColors.primary : AppColors.onSurfaceVariant)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(isOn.wrappedValue
                            ? AppColors.primaryContainer.opacity(0.5)
                            : AppColors.surfaceContainerHigh)
                    )
                Text(label)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(isOn.wrappedValue ? "ON" : "OFF"))
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
