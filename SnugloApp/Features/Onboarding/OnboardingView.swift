import SwiftUI

// MARK: — OnboardingView (Faz 3a: Vibrant Play restyle · H-1: Localized)
// Design reference: Designs/VibrantPlay/onboarding.png
// 3-page intro with mascot assets (hippo/sloth/rabbit) + page-dot indicator.
// "Skip" top-right → goes to mainMenu.
// "Get Started" on last page → sets hasOnboarded + pushes mainMenu.
// H-2: VoiceOver — page dots labelled, action button has hint.

private struct OnboardingPage: Identifiable {
    let id: Int
    let headline: LocalizedStringKey
    let body: LocalizedStringKey
    let mascotImage: String
    let accentColor: Color
}

private let pages: [OnboardingPage] = [
    .init(id: 0,
          headline: "onboarding.page1.title",
          body: "onboarding.page1.body",
          mascotImage: "mascot-hippo",
          accentColor: AppColors.primaryContainer),
    .init(id: 1,
          headline: "onboarding.page2.title",
          body: "onboarding.page2.body",
          mascotImage: "mascot-sloth",
          accentColor: AppColors.secondaryContainer),
    .init(id: 2,
          headline: "onboarding.page3.title",
          body: "onboarding.page3.body",
          mascotImage: "mascot-rabbit",
          accentColor: AppColors.tertiaryContainer)
]

struct OnboardingView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var currentPage = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var nextButtonKey: LocalizedStringKey {
        currentPage == pages.count - 1 ? "onboarding.getStarted" : "common.next"
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Atmospheric blob (decorative)
            AppColors.primaryContainer.opacity(0.25)
                .frame(width: 500, height: 500)
                .clipShape(Circle())
                .blur(radius: 80)
                .offset(x: -80, y: -120)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            AppColors.background.ignoresSafeArea()
                .opacity(0.5)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                // — Skip button —
                HStack {
                    Spacer()
                    Button {
                        finish()
                    } label: {
                        Text("common.skip")
                            .font(AppTypography.labelSmall)
                            .tracking(0.3)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                    }
                    .contentShape(Rectangle())
                    .accessibilityLabel("Skip onboarding")
                    .accessibilityHint("Goes directly to the main menu")
                    .accessibilityIdentifier("button.onboarding.skip")
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
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: currentPage)

                Spacer()

                // — Dot indicator — (H-2: VoiceOver labelled)
                HStack(spacing: AppSpacing.sm) {
                    ForEach(pages) { page in
                        Capsule()
                            .fill(currentPage == page.id ? AppColors.primary : AppColors.surfaceContainerHigh)
                            .frame(width: currentPage == page.id ? 32 : 10, height: 10)
                            .animation(
                                reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                                value: currentPage
                            )
                    }
                }
                .padding(.bottom, AppSpacing.xl)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")

                // — Action button —
                PrimaryButton(nextButtonKey, action: handleNext)
                    .padding(.horizontal, AppSpacing.lg)
                    .shadowL1()
                    .padding(.bottom, AppSpacing.xl + AppSpacing.md)
                    .accessibilityHint(currentPage == pages.count - 1
                        ? "Completes onboarding and opens the main menu"
                        : "Advances to the next onboarding page")
                    .accessibilityIdentifier("button.onboarding.getStarted")
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .accessibilityIdentifier("screen.onboarding")
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: — Page layout

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Mascot illustration (Vibrant Play: real mascot assets)
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.35))
                    .frame(width: 240, height: 240)
                    .overlay(
                        Circle().stroke(.white.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadowL1()

                Image(page.mascotImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            }
            .accessibilityHidden(true)

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
            withAnimation(reduceMotion ? nil : .default) { currentPage += 1 }
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
