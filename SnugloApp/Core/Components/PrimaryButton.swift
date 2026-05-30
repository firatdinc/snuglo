import SwiftUI

// MARK: — PrimaryButton
// Vibrant Play spec:
//   bg: AppColors.primary (#30A7E7 blue)
//   fg: AppColors.onPrimary (white)
//   radius: AppRadius.button (100 pt — pill)
//   press: GameButtonStyle 3D slab (primaryPressed as bottom depth layer)

struct PrimaryButton: View {

    let titleKey: LocalizedStringKey
    let systemImage: String?
    let accessibilityID: String?
    var action: () -> Void

    init(_ titleKey: LocalizedStringKey, systemImage: String? = nil,
         accessibilityID: String? = nil, action: @escaping () -> Void) {
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
        }
        .buttonStyle(GameButtonStyle(variant: .primary))
        // iOS 26: custom ButtonStyle can push the identifier into a style-rendered
        // sub-node that XCTest misses. Explicit leaf node with label + button trait
        // ensures XCTest can locate the element regardless of internal style structure.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titleKey)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accessibilityID ?? "")
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
