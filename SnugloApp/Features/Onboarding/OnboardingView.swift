import SwiftUI

// MARK: — OnboardingView (Screen 02)
// Design reference: Designs/html/02-onboarding.html
//
// 3-page swipe onboarding (TabView .page style)
// Each page: illustration placeholder + headline + subtitle
// "Skip" → skip directly to mainMenu
// "Next" on last page → "Get Started" → sets hasOnboarded, navigates to mainMenu

private struct OnboardingPage {
    let headline: String
    let subtitle: String
    let accentColor: Color
    let symbol: String
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        headline: "Welcome to Snuglo",
        subtitle: "A cozy puzzle to fit your day",
        accentColor: AppColors.primaryContainer,
        symbol: "puzzlepiece.fill"
    ),
    OnboardingPage(
        headline: "Fill the Grid",
        subtitle: "Drag and drop blocks to fill every cell — no overlaps, no gaps",
        accentColor: AppColors.blockSage,
        symbol: "square.grid.3x3.fill"
    ),
    OnboardingPage(
        headline: "Daily Puzzles",
        subtitle: "A fresh puzzle every day. Build your streak and collect stars",
        accentColor: AppColors.blockPeach,
        symbol: "star.fill"
    )
]

struct OnboardingView: View {

    @Environment(AppRouter.self) private var router
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                skipButton
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)

                pageContent
                    .frame(maxHeight: .infinity)

                bottomArea
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: — Skip

    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                complete()
            }
            .font(AppTypography.labelSmall)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.onSurfaceVariant)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: — Paged content

    private var pageContent: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageCard(page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.35), value: currentPage)
    }

    private func pageCard(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Illustration placeholder
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.card + 12, style: .continuous)
                    .fill(page.accentColor.opacity(0.25))
                    .frame(width: 260, height: 260)
                    .shadowL1()

                Image(systemName: page.symbol)
                    .font(.system(size: 80, weight: .regular))
                    .foregroundStyle(AppColors.primary.opacity(0.7))
            }

            // Text
            VStack(spacing: AppSpacing.sm) {
                Text(page.headline)
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(AppColors.onSurface)
                    .multilineTextAlignment(.center)
                    .tracking(-0.6)

                Text(page.subtitle)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Bottom: dots + CTA

    private var bottomArea: some View {
        VStack(spacing: AppSpacing.xl) {
            // Page indicator dots
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? AppColors.primary : AppColors.surfaceContainerHighest)
                        .frame(width: index == currentPage ? 28 : 10, height: 10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }

            // CTA button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    complete()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    .shadowL1()
            }
        }
    }

    // MARK: — Complete

    private func complete() {
        hasOnboarded = true
        // Replace path — go to mainMenu without back
        router.path = [.mainMenu]
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        OnboardingView()
    }
    .environment(AppRouter())
}
