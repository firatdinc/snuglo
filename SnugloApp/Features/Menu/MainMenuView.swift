import SwiftUI

// MARK: — MainMenuView
// Ref: Designs/html/03-main-menu.html
// Root of the tab experience. Hosts a native TabView with 4 tabs.
// Reached from SplashView via router.push(.mainMenu).
// Navigation back to mainMenu hidden — splash flow is one-way.

struct MainMenuView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        // Bindable wrapper needed because AppRouter is @Observable (not ObservableObject)
        let routerBindable = Bindable(router)

        TabView(selection: routerBindable.selectedTab) {

            // ── PLAY ──────────────────────────────────────────
            PlayTabContent()
                .tabItem {
                    Label("Play", systemImage: "puzzlepiece.fill")
                }
                .tag(AppTab.play)

            // ── LEVELS ────────────────────────────────────────
            LevelsListView()
                .tabItem {
                    Label("Levels", systemImage: "square.grid.3x3.fill")
                }
                .tag(AppTab.levels)

            // ── STATS ─────────────────────────────────────────
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.stats)

            // ── SHOP ──────────────────────────────────────────
            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(AppTab.shop)
        }
        .tint(AppColors.primary)
        .toolbarBackground(AppColors.surface, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }
}

// MARK: — Play Tab Content
// Inline so it shares the same NavigationStack from RootView.

private struct PlayTabContent: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                progressPill
                    .frame(maxWidth: .infinity, alignment: .center)

                dailyPuzzleCard

                continueSection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Snuglo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.push(.settings)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.shop)
                } label: {
                    Image(systemName: "bag")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
        }
        .toolbarBackground(AppColors.surface.opacity(0.85), for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }

    // MARK: — Progress pill

    private var progressPill: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.tertiary)
            (
                Text("Level 12 ")
                    .font(AppTypography.numericLabel)
                    .foregroundStyle(AppColors.onSurface)
                + Text("/ 240")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            )
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm - 2)
        .background(AppColors.surfaceContainer, in: Capsule())
        .overlay(Capsule().stroke(AppColors.surfaceContainerHigh, lineWidth: 1.5))
        .shadowL1()
    }

    // MARK: — Daily Puzzle hero card

    private var dailyPuzzleCard: some View {
        VStack(spacing: 0) {
            // Hero image area (real image: Faz H)
            ZStack(alignment: .topLeading) {
                AppColors.secondaryContainer.opacity(0.2)
                    .frame(height: 160)

                LinearGradient(
                    colors: [AppColors.primaryContainer.opacity(0.3), .clear],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                // Date badge
                Text("May 24")
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.horizontal, AppSpacing.sm + 4)
                    .padding(.vertical, AppSpacing.xs + 2)
                    .background(
                        AppColors.surfaceContainerLowest.opacity(0.9),
                        in: RoundedRectangle(cornerRadius: AppSpacing.sm, style: .continuous)
                    )
                    .padding(AppSpacing.md)
            }
            .clipped()

            // Footer
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Daily Puzzle")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)
                    Label("Refresh in 4h 12m", systemImage: "clock")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Spacer()

                // Play button
                Button {
                    router.push(.game(levelID: "daily"))
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.onPrimaryContainer)
                        .frame(width: 56, height: 56)
                        .background(
                            AppColors.primaryContainer,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(.white.opacity(0.5))
                                .frame(height: 1)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.md + 4)
            .background(AppColors.surfaceContainerLowest)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.6))
                .frame(height: 1)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .shadowL1()
    }

    // MARK: — Continue section

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Continue")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                Button("View Map") {}
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, AppSpacing.xs)

            Button {
                router.push(.game(levelID: "woodland-12"))
            } label: {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.block + 2, style: .continuous)
                            .fill(AppColors.surfaceContainer)
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.block + 2, style: .continuous)
                                    .stroke(AppColors.surfaceContainerHigh, lineWidth: 1)
                            )
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(AppColors.primary.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Woodland Retreat")
                            .font(AppTypography.headlineMedium)
                            .foregroundStyle(AppColors.onSurface)
                        Text("Level 12")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        HStack(spacing: AppSpacing.sm) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(AppColors.surfaceContainerHigh)
                                    Capsule()
                                        .fill(AppColors.primaryContainer)
                                        .frame(width: geo.size.width * 0.65)
                                }
                            }
                            .frame(height: 12)

                            Text("65%")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    AppColors.surfaceContainerLowest,
                    in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
                }
                .shadowL1()
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        MainMenuView()
            .navigationBarBackButtonHidden()
    }
    .environment(AppRouter())
}
