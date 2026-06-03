import SwiftUI

// MARK: — EmptyStateView
// A tasteful zero-state: a soft icon + one helpful line. Single-palette.

struct EmptyStateView: View {
    let icon: String
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.45))
            Text(titleKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}
