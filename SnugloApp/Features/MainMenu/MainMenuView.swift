import SwiftUI

// MARK: — MainMenuView (Screen 03)
// Design reference: Designs/html/03-main-menu.html
//
// Structure:
//   • Fixed top bar: settings gear | "Snuglo" wordmark | shop bag
//   • Scrollable content:
//       – Level progress pill "Level 12 / 240"
//       – Daily Puzzle hero card (date, countdown, play ▶)
//       – Continue card (pack thumbnail, name, level, progress bar)
//   • Bottom tab bar (Play active)

struct MainMenuView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                scrollContent
            }

            BottomTabBar()
        }
        .navigationBarHidden(true)
        .onAppear { router.selectedTab = .play }
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            Button {
                router.push(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Snuglo")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)

            Spacer()

            Button {
                router.selectTab(.shop)
            } label: {
                Image(systemName: "bag.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
    }

    // MARK: — Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {
                progressPill
                dailyPuzzleCard
                continueSection
                Spacer(minLength: 80) // clearance for tab bar
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: — Progress pill

    private var progressPill: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.tertiary)

            Text("Level 12")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
            +
            Text(" / 240")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs + 2)
        .background(AppColors.surfaceContainer)
        .overlay(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .stroke(AppColors.surfaceContainerHigh, lineWidth: 1.5)
        )
        .clipShape(Capsule())
        .shadowL1()
    }

    // MARK: — Daily Puzzle card

    // Faz D-2: PackProvider.dailyPuzzle() ile gerçek gridSize badge.
    private var dailyGridSize: Int { PackProvider.dailyPuzzle().width }

    private var dailyDateBadge: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }

    private var dailyPuzzleCard: some View {
        Button {
            // Faz D-2: "daily" levelId → GameView'de PackProvider.dailyPuzzle()
            router.push(.gamePlay(levelId: "daily"))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image placeholder
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.primaryContainer.opacity(0.4),
                                    AppColors.blockSage.opacity(0.2)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .frame(height: 140)

                    // Date badge — dynamic
                    Text(dailyDateBadge)
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.background.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(AppSpacing.md)

                    // GridSize indicator — from engine
                    Text("\(dailyGridSize)×\(dailyGridSize)")
                        .font(AppTypography.labelSmall)
                        .tracking(0.4)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primaryContainer.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                // Card content
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Daily Puzzle")
                            .font(AppTypography.headlineLarge)
                            .foregroundStyle(AppColors.onSurface)
                            .tracking(-0.6)

                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                            Text("Refresh in 4h 12m")
                                .font(AppTypography.bodyMedium)
                        }
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    Spacer()

                    // Play button
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.primaryContainer)
                            .frame(width: 56, height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                                    .offset(y: -0.5)
                            )
                            .shadowL1()

                        Image(systemName: "play.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .padding(AppSpacing.md + 4)
                .background(AppColors.background)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            )
            .shadowL1()
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
    }

    // MARK: — Continue section

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Continue")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)

                Spacer()

                Button("View All") {
                    router.selectTab(.levels)
                }
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, AppSpacing.xs)

            if let pack = MockData.continuePack, let level = MockData.continueLevel {
                continueCard(pack: pack, level: level)
            } else {
                // No continue item — invite to start
                Button {
                    router.selectTab(.levels)
                } label: {
                    HStack {
                        Text("Start your first level")
                            .font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppColors.primary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.primaryContainer.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func continueCard(pack: Pack, level: LevelItem) -> some View {
        Button {
            router.push(.gamePlay(levelId: level.id))
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Pack thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(pack.accentColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.surfaceContainerHigh, lineWidth: 1)
                        )

                    Image(systemName: pack.iconSymbol)
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.primary.opacity(0.7))
                }

                // Info
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(pack.title)
                            .font(AppTypography.headlineMedium)
                            .foregroundStyle(AppColors.onSurface)
                            .lineLimit(1)

                        Text("Level \(level.number)")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    // Progress bar
                    HStack(spacing: AppSpacing.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 99, style: .continuous)
                                    .fill(AppColors.surfaceContainerHighest)
                                    .frame(height: 10)

                                RoundedRectangle(cornerRadius: 99, style: .continuous)
                                    .fill(AppColors.primaryContainer)
                                    .frame(width: geo.size.width * pack.progressFraction, height: 10)
                            }
                        }
                        .frame(height: 10)

                        Text("\(Int(pack.progressFraction * 100))%")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            )
            .shadowL1()
        }
        .buttonStyle(.plain)
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        MainMenuView()
    }
    .environment(AppRouter())
}
