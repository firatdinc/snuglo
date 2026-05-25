import SwiftUI

// MARK: — PrimaryButton
// Stitch Nordic Hearth spec:
//   bg: AppColors.primary (lavender #65587A)
//   fg: AppColors.onPrimary (white)
//   radius: AppRadius.button (14 pt)
//   press: scale 0.98 + bg darkens slightly via opacity

struct PrimaryButton: View {

    let titleKey: LocalizedStringKey
    let systemImage: String?
    var action: () -> Void

    @State private var isPressed = false

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
            .foregroundStyle(AppColors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                AppColors.primary.opacity(isPressed ? 0.85 : 1.0),
                in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
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
