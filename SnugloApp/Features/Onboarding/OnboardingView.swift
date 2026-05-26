import SwiftUI

// MARK: — OnboardingView (H-1: Localized)
// Ref: Designs/html/02-onboarding.html
// 3-page intro with page-dot indicator.
// "Skip" top-right → goes to mainMenu.
// "Get Started" on last page → sets hasOnboarded + pushes mainMenu.
// H-1: headline/body fields changed to LocalizedStringKey for i18n.
// H-2: VoiceOver — page dots labelled, action button has hint.

private struct OnboardingPage: Identifiable {
    let id: Int
    let headline: LocalizedStringKey
    let body: LocalizedStringKey
    let symbol: String
    let accentColor: Color
}

private let pages: [OnboardingPage] = [
    .init(id: 0,
          headline: "onboarding.page1.title",
          body: "onboarding.page1.body",
          symbol: "puzzlepiece.fill",
          accentColor: AppColors.primaryContainer),
    .init(id: 1,
          headline: "onboarding.page2.title",
          body: "onboarding.page2.body",
          symbol: "rectangle.split.3x3.fill",
          accentColor: AppColors.secondaryContainer),
    .init(id: 2,
          headline: "onboarding.page3.title",
          body: "onboarding.page3.body",
          symbol: "calendar.badge.clock",
          accentColor: AppColors.tertiaryContainer)
]

struct OnboardingView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var currentPage = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // H-1: Computed key for the primary action button.
    private var nextButtonKey: LocalizedStringKey {
        currentPage == pages.count - 1 ? "onboarding.getStarted" : "common.next"
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Atmospheric blob
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
                    .accessibilityIdentifier("button.onboarding.skip")  // Faz I-2
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
                            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
                // H-2: Entire dot row combined as one VoiceOver element
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")

                // — Action button — (v1.1: PrimaryButton reusable component)
                PrimaryButton(nextButtonKey, action: handleNext)
                    .padding(.horizontal, AppSpacing.lg)
                    .shadowL1()
                .padding(.bottom, AppSpacing.xl + AppSpacing.md)
                // H-2: hint changes based on page
                .accessibilityHint(currentPage == pages.count - 1
                    ? "Completes onboarding and opens the main menu"
                    : "Advances to the next onboarding page")
                // Faz I-2: identifier matches the last-page "Get Started" label
                .accessibilityIdentifier("button.onboarding.getStarted")
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .accessibilityIdentifier("screen.onboarding")  // Faz I-2
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: — Page layout

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Illustration placeholder (decorative — content text provides context)
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
            .accessibilityHidden(true) // Decorative: headline below conveys meaning

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
