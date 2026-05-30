import SwiftUI

// MARK: — SecondaryButton
// Vibrant Play spec:
//   bg: AppColors.surfaceContainerLowest (white)
//   border: 1.5px AppColors.divider (#dbe4ea)
//   fg: AppColors.softCocoa (#141d21)
//   radius: AppRadius.button (100 pt — pill)
//   press: GameButtonStyle 3D slab (outlineVariant as bottom depth layer)

struct SecondaryButton: View {

    let titleKey: LocalizedStringKey
    let systemImage: String?
    var action: () -> Void

    init(_ titleKey: LocalizedStringKey, systemImage: String? = nil, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(titleKey)
                    .font(AppTypography.headlineSmall)
            }
            .foregroundStyle(AppColors.softCocoa)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GameButtonStyle(variant: .secondary))
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 16) {
        SecondaryButton("Restart", systemImage: "arrow.counterclockwise") {}
        SecondaryButton("Home", systemImage: "house") {}
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
