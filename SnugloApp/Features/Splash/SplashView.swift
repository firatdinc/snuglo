import SwiftUI

// MARK: — SplashView (Screen 01)
// Design reference: Designs/html/01-splash.html
//
// Layout:
//   • 3×3 pastel block grid logo (72pt, gap 4pt)
//   • "Snuglo" wordmark below
// Behavior:
//   • Fade-in on appear
//   • After 1.2 s → pushes .onboarding (first launch) or .mainMenu (returning user)
//   • AppStorage("hasOnboarded") flag persists across launches

struct SplashView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    // 3×3 logo block colors (matches 01-splash.html grid)
    // Row-major order (top-left → bottom-right)
    private let logoBlocks: [Color] = [
        AppColors.primaryContainer,          // (0,0) lavender
        AppColors.surfaceContainerHigh,      // (1,0) neutral
        AppColors.blockPeach,                // (2,0) peach ≈ secondary-container
        AppColors.surfaceContainerHigh,      // (0,1) neutral
        AppColors.blockCream,                // (1,1) cream ≈ tertiary-container
        AppColors.surfaceContainerHigh,      // (2,1) neutral
        AppColors.blockBlush,                // (0,2) blush ≈ error-container tint
        AppColors.surfaceContainerHigh,      // (1,2) neutral
        AppColors.surfaceContainerHigh,      // (2,2) neutral
    ]

    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 10

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                logoGrid
                wordmark
            }
            .opacity(opacity)
            .offset(y: yOffset)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Fade in
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                yOffset = 0
            }
            // Navigate after 1.2 s
            Task {
                try? await Task.sleep(for: .milliseconds(1_200))
                await MainActor.run {
                    router.push(hasOnboarded ? .mainMenu : .onboarding)
                }
            }
        }
    }

    // MARK: — Logo

    private var logoGrid: some View {
        let gridSize: CGFloat = 72
        let gap: CGFloat = AppSpacing.xs      // 4 pt

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: 3),
            spacing: gap
        ) {
            ForEach(Array(logoBlocks.enumerated()), id: \.offset) { _, color in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color)
                    .shadow(color: AppColors.shadowAmbient.opacity(0.06), radius: 4, x: 0, y: 2)
            }
        }
        .frame(width: gridSize, height: gridSize)
        .padding(AppSpacing.sm)
        .background(AppColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.block + 4, style: .continuous))
        .shadowL1()
    }

    private var wordmark: some View {
        Text("Snuglo")
            .font(AppTypography.headlineLarge)
            .foregroundStyle(AppColors.onSurface)
            .tracking(-0.6)
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        SplashView()
    }
    .environment(AppRouter())
}
