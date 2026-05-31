import SwiftUI
import SnugloEngine

// MARK: — MainMenuView (Faz 2: Vibrant Play restyle)
// Design reference: Designs/VibrantPlay/main-menu.png + main-menu.html
// H-2: VoiceOver — daily puzzle card labelled, progress pill labelled, top-bar buttons hinted.
//
// Tab content dispatch:
//   .play / .home → scrollContent (Play tab = main puzzle menu)
//   .levels       → scrollContent (never reached — Levels tab pushes .levelsList route)
//   .stats        → StatsView
//   .shop         → ShopView
//   .settings     → SettingsView (backward compat for LevelsListView.selectTab(.settings))

struct MainMenuView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                tabContent
            }

        }
        .toolbar(.hidden, for: .navigationBar)
        // iOS 26: .contain ensures children (topBar buttons, tab content) remain
        // independently queryable by XCTest inside this identified container.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.mainMenu")
    }

    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .play, .home, .levels, .leaderboard:
            scrollContent
        case .stats:
            StatsView()
        case .shop:
            ShopView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        }
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            Button {
                router.selectTab(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens the settings screen")
            .accessibilityIdentifier("button.menu.settings")

            Spacer()

            Text("app.name")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)
                .accessibilityHidden(true)

            Spacer()

            Button {
                router.selectTab(.shop)
            } label: {
                Image(systemName: "bag.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shop")
            .accessibilityHint("Opens the in-app shop")
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
        // iOS 26: .contain ensures Settings and Shop buttons remain
        // independently queryable by XCTest inside this HStack.
        .accessibilityElement(children: .contain)
    }

    // MARK: — Scroll content

    private var scrollContent: some View {
        let completedCount = ProgressStore.shared.totalLevelsCompleted()
        return ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {
                progressPill
                dailyPuzzleCard
                continueSection
                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
        .id(completedCount)
    }

    // MARK: — Progress pill

    private var progressPill: some View {
        let completed = ProgressStore.shared.totalLevelsCompleted()
        let total = 240
        let current = min(completed + 1, total)
        return HStack(spacing: AppSpacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.tertiary)
                .accessibilityHidden(true)

            Text(verbatim: "Level \(current)")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
            +
            Text(verbatim: " / \(total)")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("On level \(current) of \(total). \(completed) completed.")
    }

    // MARK: — Daily Puzzle card

    private var dailyGridSize: Int { DailyPuzzle.gridSize(for: Date()) }

    private var refreshCountdownString: String {
        let cal = Calendar.current
        let now = Date()
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) else {
            return "—"
        }
        let fmt = DateComponentsFormatter()
        fmt.unitsStyle = .abbreviated
        fmt.allowedUnits = [.hour, .minute]
        fmt.calendar = cal
        return fmt.string(from: now, to: tomorrow) ?? "—"
    }

    private var dailyDateBadge: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }

    private var dailyPuzzleCard: some View {
        Button {
            router.push(.gamePlay(levelId: "daily"))
        } label: {
            dailyPuzzleCardLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("menu.dailyPuzzle"))
        .accessibilityHint("Tap to play today's puzzle")
        .accessibilityIdentifier("button.menu.dailyPuzzle")
    }

    private var dailyPuzzleCardLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image with floating mascot
            ZStack(alignment: .topLeading) {
                // Hero image (Vibrant Play: real asset, not gradient)
                Image("hero-splash")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .accessibilityHidden(true)

                // Subtle gradient overlay for badge readability
                LinearGradient(
                    colors: [.clear, AppColors.primaryContainer.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .accessibilityHidden(true)

                // Mascot — top-right corner, peeking into the card
                Image("mascot-hippo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 96)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, AppSpacing.sm)
                    .accessibilityHidden(true)

                // Date badge — top-left
                Text(verbatim: dailyDateBadge)
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.onSurface)
                    .padding(.horizontal, AppSpacing.sm + 4)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.background.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(AppSpacing.md)
                    .accessibilityHidden(true)

                // Grid-size badge — top-right
                Text(verbatim: "\(dailyGridSize)×\(dailyGridSize)")
                    .font(AppTypography.labelSmall)
                    .tracking(0.4)
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.sm + 4)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.primaryContainer.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                    .accessibilityHidden(true)
            }

            // Card content area
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("menu.dailyPuzzle")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .accessibilityHidden(true)
                        Text(verbatim: String(
                            format: NSLocalizedString("menu.refresh", comment: ""),
                            refreshCountdownString
                        ))
                        .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Spacer()

                // Decorative play badge
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
                .accessibilityHidden(true)
            }
            .padding(AppSpacing.md + 4)
            .background(AppColors.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .cardSurface()
        .contentShape(Rectangle())
    }

    // MARK: — Continue section

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("menu.continue")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)

                Spacer()

                Button {
                    router.push(.levelsList)
                } label: {
                    Text("menu.viewAll")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityLabel("View all level packs")
            }
            .padding(.horizontal, AppSpacing.xs)

            if let pack = PackProvider.continuePack(), let level = PackProvider.continueLevel() {
                continueCard(pack: pack, level: level)
            } else {
                Button {
                    router.push(.levelsList)
                } label: {
                    HStack {
                        Text("menu.startFirst")
                            .font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppColors.primary)
                            .accessibilityHidden(true)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.primaryContainer.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the levels list to start your first puzzle")
            }
        }
    }

    private func continueCard(pack: Pack, level: LevelItem) -> some View {
        Button {
            router.push(.game(levelID: level.id))
        } label: {
            continueCardLabel(pack: pack, level: level)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(pack.title), Level \(level.number), \(Int(pack.progressFraction * 100)) percent complete"
        )
        .accessibilityHint("Tap to continue this level")
        .accessibilityIdentifier("button.menu.continue")
    }

    private func continueCardLabel(pack: Pack, level: LevelItem) -> some View {
        HStack(spacing: AppSpacing.md) {
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
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(verbatim: pack.title)
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                        .lineLimit(1)

                    Text(verbatim: "Level \(level.number)")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

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

                    Text(verbatim: "\(Int(pack.progressFraction * 100))%")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .cardSurface()
        .contentShape(Rectangle())
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        MainMenuView()
    }
    .environment(AppRouter())
}
