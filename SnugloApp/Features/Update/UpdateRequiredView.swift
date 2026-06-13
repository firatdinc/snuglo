import SwiftUI

// MARK: — UpdateRequiredView
// Full-screen, NON-dismissible wall shown when the running app is below the
// remote `minVersion`. The only action is to open the App Store. Presented from
// RootView at the very top of the z-stack so nothing behind it is reachable.

struct UpdateRequiredView: View {

    let onUpdate: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColors.primaryContainer.opacity(0.5))
                        .frame(width: 132, height: 132)
                    MascotView(name: "mascot-sloth", size: 96, clipCircle: false)
                        .accessibilityHidden(true)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.primary)
                        .background(AppColors.background, in: Circle())
                        .offset(x: 46, y: 46)
                        .accessibilityHidden(true)
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: AppSpacing.sm) {
                    Text("update.required.title")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.5)
                        .foregroundStyle(AppColors.onSurface)
                        .multilineTextAlignment(.center)

                    Text("update.required.message")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                Spacer()

                PrimaryButton("update.required.cta", systemImage: "arrow.up.right.square.fill") {
                    onUpdate()
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl + AppSpacing.md)
                .accessibilityIdentifier("update.required.cta")
            }
        }
        .interactiveDismissDisabled(true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.updateRequired")
        .onAppear {
            let anim: Animation? = reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8)
            withAnimation(anim) { appeared = true }
        }
    }
}
