import SwiftUI

// MARK: — RowDivider
// Stitch Nordic Hearth spec:
//   color: AppColors.divider (#EDE6DA)
//   thickness: 1 pt
//   horizontal padding: AppSpacing.lg (24 pt) built-in via inset modifier at call site

struct RowDivider: View {

    var body: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 1)
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 0) {
        Text("Row A")
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        RowDivider()
            .padding(.horizontal, 24)
        Text("Row B")
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
    }
}
