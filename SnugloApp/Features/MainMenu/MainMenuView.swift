import SwiftUI
import SnugloEngine

// MARK: — MainMenuView (Screen 03 · H-1: Localized)
// Design reference: Designs/html/03-main-menu.html
// H-2: VoiceOver — daily puzzle card labelled, progress pill labelled, top-bar buttons hinted.

struct MainMenuView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                tabContent
            }

            BottomTabBar()
        }
        .navigationBarHidden(true)
        .accessibilityIdentifier("screen.mainMenu")
    }

    // Faz I-2: tabs are now home / stats / shop / settings
    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .home:
            scrollContent
        case .stats:
            StatsView()
        case .shop:
            ShopView()
        case .settings:
            SettingsView()
        }
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            // Faz I-2: settings is now a tab, not a pushed route
            Button {
                router.selectTab(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens the settings screen")

            Spacer()

            Text("app.name")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)
                .accessibilityHidden(true) // App name — not useful to repeat on every screen

            Spacer()

            Button {
                router.selectTab(.shop)
            } label: {
                Image(systemName: "bag.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Shop")
            .accessibilityHint("Opens the in-app shop")
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
        let completed = ProgressStore.shared.totalLevelsCompleted()
        let total = 240
        // v1.1.1: pill reads as "Level X / Total" where X is the next level the
        // player will play, matching the Stitch design ("Level 12 / 240" when
        // 11 are done). Was showing "Level 0 / 240" for fresh players.
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
        // H-2: combined element for VoiceOver
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("On level \(current) of \(total). \(completed) completed.")
    }

    // MARK: — Daily Puzzle card

    /// Avoid running the full level generator on every body render — only
    /// the gridSize is needed for the badge, which we can derive cheaply
    /// from DailyPuzzle's weekday rotation.
    private var dailyGridSize: Int { DailyPuzzle.gridSize(for: Date()) }

    /// H-1 BLOCKER 2: real locale-aware countdown to next midnight.
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
            VStack(alignment: .leading, spacing: 0) {
                // Hero image placeholder (decorative gradient)
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
                        .accessibilityHidden(true)

                    // Date badge
                    Text(verbatim: dailyDateBadge)
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.background.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(AppSpacing.md)
                        .accessibilityHidden(true) // conveyed in card label

                    // GridSize indicator
                    Text(verbatim: "\(dailyGridSize)×\(dailyGridSize)")
                        .font(AppTypography.labelSmall)
                        .tracking(0.4)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primaryContainer.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .accessibilityHidden(true) // conveyed in card label
                }

                // Card content
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
                            // H-1 BLOCKER 2: real countdown + localized format
                            Text(verbatim: String(
                                format: NSLocalizedString("menu.refresh", comment: ""),
                                refreshCountdownString
                            ))
                            .font(AppTypography.bodyMedium)
                        }
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    Spacer()

                    // Play button (decorative — button handles tap)
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
            // v1.1 bug fix: ensure entire card is hit-testable. Without this
            // SwiftUI may miss taps over the inner ZStack regions that have
            // .frame(maxWidth: .infinity, maxHeight: .infinity) overlays.
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        // H-2: meaningful label for VoiceOver
        .accessibilityLabel(Text("menu.dailyPuzzle"))
        .accessibilityHint("Tap to play today's puzzle")
        // Faz I-2: UITest smoke identifier (updated spec)
        .accessibilityIdentifier("button.menu.dailyPuzzle")
    }

    // MARK: — Continue section

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("menu.continue")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)

                Spacer()

                // Faz I-2: levels is no longer a tab; push .levelsList route
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

            // v1.1 bug fix: pull live progress from PackProvider/ProgressStore,
            // not hardcoded MockData (was showing "Cozy Beginnings Level 13"
            // for a fresh player with zero progress).
            if let pack = PackProvider.continuePack(), let level = PackProvider.continueLevel() {
                continueCard(pack: pack, level: level)
            } else {
                // Faz I-2: push .levelsList route (levels tab removed)
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
            router.push(.gamePlay(levelId: level.id))
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Pack thumbnail (decorative — label conveys pack info)
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

                // Info
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

                        Text(verbatim: "\(Int(pack.progressFraction * 100))%")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .accessibilityHidden(true) // conveyed by card label
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
        }
        .buttonStyle(.plain)
        // H-2: combined label with progress context
        .accessibilityLabel("\(pack.title), Level \(level.number), \(Int(pack.progressFraction * 100)) percent complete")
        .accessibilityHint("Tap to continue this level")
        // Faz I-2: UITest continue CTA identifier (updated spec)
        .accessibilityIdentifier("button.menu.continue")
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        MainMenuView()
    }
    .environment(AppRouter())
}
