import SwiftUI

// MARK: — OnboardingView
// Ref: Designs/html/02-onboarding.html
// 3-page intro with page-dot indicator.
// "Skip" top-right → goes to mainMenu.
// "Get Started" on last page → sets hasOnboarded + pushes mainMenu.

private struct OnboardingPage: Identifiable {
    let id: Int
    let headline: String
    let body: String
    let symbol: String
    let accentColor: Color
}

private let pages: [OnboardingPage] = [
    .init(id: 0,
          headline: "Welcome to Snuglo",
          body: "A cozy puzzle to fit your day",
          symbol: "puzzlepiece.fill",
          accentColor: AppColors.primaryContainer),
    .init(id: 1,
          headline: "Fill the Grid",
          body: "Drag and drop pieces to fill every cell. No overlaps, no gaps.",
          symbol: "rectangle.split.3x3.fill",
          accentColor: AppColors.secondaryContainer),
    .init(id: 2,
          headline: "Cozy Every Day",
          body: "Daily puzzles, streaks, and four themed packs to explore at your pace.",
          symbol: "calendar.badge.clock",
          accentColor: AppColors.tertiaryContainer)
]

struct OnboardingView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Atmospheric blob
            AppColors.primaryContainer.opacity(0.25)
                .frame(width: 500, height: 500)
                .clipShape(Circle())
                .blur(radius: 80)
                .offset(x: -80, y: -120)
                .ignoresSafeArea()

            AppColors.background.ignoresSafeArea()
                .opacity(0.5)

            VStack(spacing: 0) {
                // — Skip button —
                HStack {
                    Spacer()
                    Button("Skip") {
                        finish()
                    }
                    .font(AppTypography.labelSmall)
                    .tracking(0.3)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)

                Spacer()

                // — Page content —
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        pageContent(page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                Spacer()

                // — Dot indicator —
                HStack(spacing: AppSpacing.sm) {
                    ForEach(pages) { page in
                        Capsule()
                            .fill(currentPage == page.id ? AppColors.primary : AppColors.surfaceContainerHigh)
                            .frame(width: currentPage == page.id ? 32 : 10, height: 10)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, AppSpacing.xl)

                // — Action button —
                Button(action: handleNext) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                        .shadowL1()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl + AppSpacing.md)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: — Page layout

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Illustration placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(page.accentColor.opacity(0.35))
                    .frame(width: 260, height: 260)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadowL1()

                Image(systemName: page.symbol)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(AppColors.primary.opacity(0.7))
            }

            VStack(spacing: AppSpacing.sm) {
                Text(page.headline)
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.onSurface)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Actions

    private func handleNext() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        hasOnboarded = true
        router.push(.mainMenu)
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
    }
    .environment(AppRouter())
}
