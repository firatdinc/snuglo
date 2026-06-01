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
            tabContent
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
        Text("app.name")
            .font(AppTypography.headlineMedium)
            .foregroundStyle(AppColors.primary)
            .tracking(-0.4)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 56)
            .padding(.horizontal, AppSpacing.lg)
            .background(AppColors.background)
            .accessibilityHidden(true)
    }

    // MARK: — Scroll content

    private var scrollContent: some View {
        let completedCount = ProgressStore.shared.totalLevelsCompleted()
        return ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.lg) {
                streakBadge
                dailyPuzzleCard
                progressPill
                continueSection
                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
        }
        .id(completedCount)
        .task { await DailyReminderService.shared.refreshAuthorizationState() }
        .onAppear { ProgressStore.shared.refreshPlayStreak() }
    }

    // MARK: — Streak badge (play streak — any level, any day)

    private var streakBadge: some View {
        let streak = ProgressStore.shared.playStreak
        let best = ProgressStore.shared.longestPlayStreak
        let lit = streak > 0
        return HStack(spacing: AppSpacing.sm) {
            Image(systemName: lit ? "flame.fill" : "flame")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(lit ? AppColors.tertiary : AppColors.onSurfaceVariant.opacity(0.55))
                .accessibilityHidden(true)

            if lit {
                Text(verbatim: String(format: NSLocalizedString("menu.streak.days", comment: ""), streak))
                    .font(AppTypography.numericLabel)
                    .foregroundStyle(AppColors.onSurface)
            } else {
                Text("menu.streak.start")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()

            if best > 0 {
                Text(verbatim: String(format: NSLocalizedString("menu.streak.best", comment: ""), best))
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfaceContainer)
        .overlay(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .stroke(lit ? AppColors.tertiary.opacity(0.35) : AppColors.surfaceContainerHigh, lineWidth: 1.5)
        )
        .clipShape(Capsule())
        .shadowL1()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lit
            ? "Play streak: \(streak) days. Best \(best)."
            : "No active streak. Play any level today to start one.")
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

    // Multi-level daily challenge state.
    private var dailySolvedCount: Int { ProgressStore.shared.dailySolvedCount() }
    private var dailyTotal: Int { ProgressStore.dailyLevelCount }
    private var dailyIsComplete: Bool { ProgressStore.shared.isDailyAllComplete() }

    private var dailyProgressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<dailyTotal, id: \.self) { i in
                Capsule()
                    .fill(i < dailySolvedCount ? AppColors.primary : AppColors.outlineVariant.opacity(0.4))
                    .frame(width: i < dailySolvedCount ? 18 : 10, height: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private var dailyDateBadge: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }

    private var reminder: DailyReminderService { DailyReminderService.shared }

    /// Live HH:MM:SS countdown until the daily refreshes (next UTC midnight).
    private func dailyCountdown(_ now: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let next = cal.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? now
        let s = max(0, Int(next.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    // Card uses onTapGesture (not a Button) so the embedded bell toggle can have
    // its own independent tap target without nested-button conflicts.
    private var dailyPuzzleCard: some View {
        dailyPuzzleCardLabel
            .contentShape(Rectangle())
            .onTapGesture {
                guard !dailyIsComplete else { return }
                router.push(.gamePlay(levelId: "daily-\(dailySolvedCount)"))
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("button.menu.dailyPuzzle")
    }

    private func toggleReminder() {
        Task { await reminder.setEnabled(!reminder.isEnabled) }
    }

    private var dailyPuzzleCardLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full hero image — scaledToFit so nothing is cropped, maxHeight keeps card compact
            Image("hero-splash")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 180)
                .overlay(alignment: .topLeading) {
                    // Date badge
                    Text(verbatim: dailyDateBadge)
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.onSurface)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.background.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(AppSpacing.sm)
                }
                .overlay(alignment: .topTrailing) {
                    // Grid-size badge
                    Text(verbatim: "\(dailyGridSize)×\(dailyGridSize)")
                        .font(AppTypography.labelSmall)
                        .tracking(0.4)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primaryContainer.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(AppSpacing.sm)
                }
                .accessibilityHidden(true)

            // Card content area
            HStack(alignment: .center, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("menu.dailyPuzzle")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)

                    // Progress dots — filled = solved daily levels.
                    dailyProgressDots

                    // Live refresh countdown (ticks every second).
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 13))
                                .accessibilityHidden(true)
                            if dailyIsComplete {
                                Text(verbatim: NSLocalizedString("menu.dailyNext", comment: "")
                                     + " " + dailyCountdown(ctx.date))
                                    .font(AppTypography.bodyMedium)
                                    .monospacedDigit()
                            } else {
                                Text(verbatim: "\(dailySolvedCount)/\(dailyTotal)  ·  " + String(
                                    format: NSLocalizedString("menu.refresh", comment: ""),
                                    dailyCountdown(ctx.date)
                                ))
                                .font(AppTypography.bodyMedium)
                                .monospacedDigit()
                            }
                        }
                        .foregroundStyle(dailyIsComplete ? AppColors.primary : AppColors.onSurfaceVariant)
                    }
                }

                Spacer()

                // Notification bell toggle (independent tap target).
                Button(action: toggleReminder) {
                    Image(systemName: reminder.isEnabled ? "bell.fill" : "bell")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(reminder.isEnabled ? AppColors.primary : AppColors.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppColors.surfaceContainerHigh))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(reminder.isEnabled ? "menu.daily.notif.on" : "menu.daily.notif.off"))
                .accessibilityIdentifier("button.menu.dailyReminder")

                // Play (incomplete) / green-sun solved badge (complete).
                if dailyIsComplete {
                    SunCheckBadge(size: 52)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.primaryContainer)
                            .frame(width: 52, height: 52)
                            .shadowL1()

                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
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

    /// Image asset (mascot) for a pack's home icon, if it has one — otherwise
    /// the view falls back to the pack's SF Symbol. Cozy Beginnings uses the
    /// sleepy sloth mascot instead of the generic leaf glyph.
    private func packMascotAsset(_ pack: Pack) -> String? {
        switch pack.id {
        case "cozy-beginnings": return "mascot-sloth"
        default:                return nil
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

                if let mascot = packMascotAsset(pack) {
                    Image(mascot)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 66, height: 66)
                } else {
                    Image(systemName: pack.iconSymbol)
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.primary.opacity(0.7))
                }
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
