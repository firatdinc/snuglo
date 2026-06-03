import SwiftUI

// MARK: — ConfirmDialog
// A modern, centred modal that replaces the system .confirmationDialog.
// Dimmed + blurred backdrop, a tinted icon badge, title + message, and a
// secondary "keep" action beside a destructive "confirm" action.

struct ConfirmDialog: View {

    let icon: String
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    let cancelKey: LocalizedStringKey
    let confirmKey: LocalizedStringKey
    var confirmIsDestructive: Bool = true
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            // Backdrop — blur + dim, tap to cancel.
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.25).ignoresSafeArea())
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)
                .transition(.opacity)

            card
                .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var card: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.errorContainer.opacity(0.6))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.error)
            }
            .padding(.top, AppSpacing.xs)

            Text(titleKey)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)

            Text(messageKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(cancelKey, action: onCancel)
                    .accessibilityIdentifier("dialog.cancel")

                Button(action: onConfirm) {
                    Text(confirmKey)
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            (confirmIsDestructive ? AppColors.error : AppColors.primary),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dialog.confirm")
            }
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: 340)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.4), lineWidth: 0.5)
        )
        .shadowL3()
        .padding(.horizontal, AppSpacing.xl)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        ConfirmDialog(
            icon: "door.left.hand.open",
            titleKey: "Quit the puzzle?",
            messageKey: "Your current progress in this level won't be saved.",
            cancelKey: "Keep playing",
            confirmKey: "Quit",
            onCancel: {}, onConfirm: {}
        )
    }
}
