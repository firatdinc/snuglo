import SwiftUI

// MARK: — PrimaryButton
// Vibrant Play spec:
//   bg: AppColors.primary (#30A7E7 blue)
//   fg: AppColors.onPrimary (white)
//   radius: AppRadius.button (100 pt — pill)
//   press: scale 0.98 + bg → AppColors.primaryPressed (#2589C1)

struct PrimaryButton: View {

    let titleKey: LocalizedStringKey
    let systemImage: String?
    let accessibilityID: String?
    var action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ titleKey: LocalizedStringKey, systemImage: String? = nil, accessibilityID: String? = nil, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.accessibilityID = accessibilityID
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
            .foregroundStyle(AppColors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                isPressed ? AppColors.primaryPressed : AppColors.primary,
                in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        // .buttonStyle(.plain) may strip the .isButton accessibility trait on some iOS versions.
        // Explicitly re-adding it ensures XCTest classifies this as a button element.
        .accessibilityAddTraits(.isButton)
        // Apply identifier directly on the Button so XCTest finds it without a wrapper element.
        .accessibilityIdentifier(accessibilityID ?? "")
        ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Next Level", systemImage: "arrow.right") {}
        PrimaryButton("Play") {}
    }
    .padding()
}
