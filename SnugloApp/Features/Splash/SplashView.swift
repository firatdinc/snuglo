import SwiftUI

// MARK: — SplashView (Faz 3a: Vibrant Play restyle)
// Design reference: Designs/VibrantPlay/splash.png
// Uses Image("hero-splash") as the primary visual (replaces 3×3 block grid).
// Splash → pushes .onboarding (first launch) or .mainMenu after 1.2 s.
// H-2: VoiceOver — hero image combined as "Snuglo logo", wordmark hidden (redundant).
// Faz I-2: UITestMode skips delay for fast, stable tests.

struct SplashView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var visible = false
    @State private var scale: CGFloat = 0.92
    /// v1.1 bug fix: store task so it can be cancelled on disappear (prevents leak if
    /// SplashView is popped by a test or back-navigation before the delay completes).
    @State private var splashTask: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // — Hero image — (Vibrant Play: real asset, not a grid logo)
                // H-2: Combined as single VoiceOver element labelled "Snuglo"
                Image("hero-splash")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .scaleEffect(scale)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                        value: scale
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Snuglo")

                // — Wordmark — hidden from VoiceOver (image already labelled "Snuglo")
                Text("Snuglo")
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.primary)
                    .accessibilityHidden(true)

                Spacer()
            }
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 10)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.8), value: visible)
        }
        .accessibilityIdentifier("screen.splash")
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            visible = true
            if !reduceMotion { scale = 1.0 }

            let isUITest = UserDefaults.standard.bool(forKey: "snuglo.uitestmode")
            let delayMs  = isUITest ? 0 : 1200

            splashTask = Task {
                if delayMs > 0 {
                    try? await Task.sleep(for: .milliseconds(delayMs))
                }
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    router.push(hasOnboarded ? .mainMenu : .onboarding)
                }
            }
        }
        .onDisappear {
            splashTask?.cancel()
        }
    }
}

#Preview {
    NavigationStack {
        SplashView()
    }
    .environment(AppRouter())
}
