import SwiftUI

// MARK: — AnnouncementBanner
// CardSurface card with a 4 pt primary accent strip on the leading edge.
// Optional CTA (PrimaryButton) and dismiss "×" button.
// All text via LocalizedStringKey — no hardcoded strings inside.

struct AnnouncementBanner: View {

    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    let ctaKey: LocalizedStringKey?
    let onCTA: (() -> Void)?
    let onDismiss: (() -> Void)?

    init(
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey,
        ctaKey: LocalizedStringKey? = nil,
        onCTA: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.ctaKey = ctaKey
        self.onCTA = onCTA
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack(alignment: .leading) {
            cardContent
            accentStrip
        }
    }

    // MARK: — Card content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(titleKey)
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text(messageKey)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)

                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("announcement.dismiss"))
                    .accessibilityIdentifier("announcement.dismiss")
                }
            }

            if let ctaKey, let onCTA {
                PrimaryButton(ctaKey, action: onCTA)
            }
        }
        // Leading padding accommodates the 4 pt accent strip + gap.
        .padding(.leading, AppSpacing.md + 8)
        .padding(.trailing, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .cardSurface()
    }

    // MARK: — Leading accent strip

    private var accentStrip: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(AppColors.primary)
            .frame(width: 4)
            .padding(.vertical, AppRadius.card)
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 16) {
        AnnouncementBanner(
            titleKey: "New Pack Unlocked!",
            messageKey: "The Winter Collection is now available in the Shop.",
            ctaKey: "common.viewAll",
            onCTA: {},
            onDismiss: {}
        )

        AnnouncementBanner(
            titleKey: "Daily Streak",
            messageKey: "You are on a 7-day streak. Keep it up!"
        )
    }
    .padding()
    .background(AppColors.background.ignoresSafeArea())
}
