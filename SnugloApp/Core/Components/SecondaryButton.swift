import SwiftUI

// MARK: — SecondaryButton
// Vibrant Play spec:
//   bg: AppColors.surfaceContainerLowest (white)
//   border: 1.5px AppColors.divider (#dbe4ea)
//   fg: AppColors.softCocoa (#141d21)
//   radius: AppRadius.button (100 pt — pill)

struct SecondaryButton: View {

    let titleKey: LocalizedStringKey
    let systemImage: String?
    var action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            .padding(.vertical, AppSpacing.md)
            .background(
                AppColors.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
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
