import SwiftUI

// MARK: — ProgressPill
// Capsule-shaped pill showing a text label and an optional fill bar (0…1).
// When `progress` is nil the pill is label-only (badge / status chip).
// When `progress` is provided a horizontal fill track renders inside the pill.

struct ProgressPill: View {

    let label: String
    let progress: Double?

    init(label: String, progress: Double? = nil) {
        self.label = label
        self.progress = progress
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
                .lineLimit(1)

            if let progress {
                progressTrack(clamped: min(1, max(0, progress)))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            Capsule()
                .fill(AppColors.surfaceContainerLowest)
                .overlay(
                    Capsule()
                        .strokeBorder(AppColors.outlineVariant.opacity(0.4), lineWidth: 0.5)
                )
        )
        .shadowL1()
    }

    private func progressTrack(clamped value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.surfaceContainerHigh)
                Capsule()
                    .fill(AppColors.primary)
                    .frame(width: value * geo.size.width)
            }
        }
        .frame(height: 8)
        .frame(minWidth: 60)
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 16) {
        ProgressPill(label: "Level 12")
        ProgressPill(label: "Daily", progress: 0.6)
        ProgressPill(label: "Complete", progress: 1.0)
    }
    .padding()
    .background(AppColors.background.ignoresSafeArea())
}
