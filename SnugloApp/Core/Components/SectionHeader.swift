import SwiftUI

// MARK: — SectionHeader
// Left-aligned section title + optional right-side action link.
// Callers pass "common.viewAll" or any other LocalizedStringKey as actionTitleKey.

struct SectionHeader: View {

    let titleKey: LocalizedStringKey
    let actionTitleKey: LocalizedStringKey?
    let action: (() -> Void)?

    init(
        _ titleKey: LocalizedStringKey,
        actionTitleKey: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.titleKey = titleKey
        self.actionTitleKey = actionTitleKey
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titleKey)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            Spacer()

            if let actionTitleKey, let action {
                Button(action: action) {
                    Text(actionTitleKey)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 20) {
        SectionHeader("Packs") {}
        SectionHeader("Daily Puzzles", actionTitleKey: "common.viewAll") {}
        SectionHeader("Statistics")
    }
    .padding()
}
