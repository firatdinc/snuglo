import SwiftUI

// MARK: — SplashView
// Ref: Designs/html/01-splash.html
// 3×3 pastel block logo + "Snuglo" wordmark, centered on warm background.
// Fades in → after 1.2 s pushes to .onboarding (first launch) or .mainMenu.

struct SplashView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var visible = false
    @State private var scale: CGFloat = 0.92

    // 3×3 block grid colours (matches HTML: primaryContainer / surfaceContainerHigh / secondaryContainer / tertiaryContainer / error-container)
    private let blockColors: [Color] = [
        AppColors.primaryContainer,
        AppColors.surfaceContainerHigh,
        AppColors.secondaryContainer,
        AppColors.surfaceContainerHigh,
        AppColors.tertiaryContainer,
        AppColors.surfaceContainerHigh,
        AppColors.blockBlush.opacity(0.8),
        AppColors.surfaceContainerHigh,
        AppColors.surfaceContainerHigh
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                // — 3×3 block grid logo —
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppColors.surfaceContainerLow)
                        .frame(width: 88, height: 88)
                        .shadowL1()

                    let cols = Array(repeating: GridItem(.fixed(22), spacing: 4), count: 3)
                    LazyVGrid(columns: cols, spacing: 4) {
                        ForEach(Array(blockColors.enumerated()), id: \.offset) { _, color in
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(color)
                                .frame(width: 22, height: 22)
                                .shadowL1()
                        }
                    }
                    .padding(8)
                }
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: scale
                )

                // — Wordmark —
                Text("Snuglo")
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.onSurface)
            }
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 10)
            .animation(.easeOut(duration: 0.8), value: visible)
        }
        .navigationBarHidden(true)
        .onAppear {
            visible = true
            scale = 1.0

            Task {
                try? await Task.sleep(for: .milliseconds(1200))
                await MainActor.run {
                    router.push(hasOnboarded ? .mainMenu : .onboarding)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SplashView()
    }
    .environment(AppRouter())
}
