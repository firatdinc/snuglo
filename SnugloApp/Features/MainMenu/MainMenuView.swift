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
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    /// Zen Mode toggle, surfaced on the home corner (was buried in Settings).
    /// When on, the home shows ONLY the Zen entry and the app shifts to the sage
    /// palette (RootView rebuilds on this key).
    @AppStorage("zenMode") private var zenMode = false
    @State private var chestReward: ChestReward?
    @State private var showSpin = false
    @State private var showCalendar = false
    @State private var showRewardsMenu = false
    @State private var showTowerNoTicket = false
    @State private var dailyShareImage: Image?

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            tabContent
        }
        // Floating rewards button + drop-down (spin / daily / chest) — only on the
        // menu tabs. Frees the home column for the prominent Zen card.
        .overlay(alignment: .bottomTrailing) {
            if isMenuTab && !zenMode { rewardsFab.padding(.trailing, AppSpacing.lg).padding(.bottom, AppSpacing.md) }
        }
        .toolbar(.hidden, for: .navigationBar)
        // iOS 26: .contain ensures children (topBar buttons, tab content) remain
        // independently queryable by XCTest inside this identified container.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.mainMenu")
        .overlay {
            if let reward = chestReward {
                ChestRevealOverlay(reward: reward) { chestReward = nil }
                    .zIndex(50)
                    .transition(.opacity)
            }
            if showSpin {
                SpinWheelOverlay { showSpin = false }
                    .zIndex(50)
                    .transition(.opacity)
            }
            if showCalendar {
                DailyCalendarView { showCalendar = false }
                    .zIndex(50)
                    .transition(.opacity)
            }
            if showTowerNoTicket {
                ConfirmDialog(
                    icon: "ticket.fill",
                    titleKey: "tower.title",
                    messageKey: "tower.needTicket",
                    cancelKey: "button.close",
                    confirmKey: "tower.getTickets",
                    confirmIsDestructive: false,
                    onCancel: { showTowerNoTicket = false },
                    onConfirm: { showTowerNoTicket = false; router.selectTab(.shop) }
                )
                .zIndex(55)
                .transition(.opacity)
            }
            if let lvl = XPStore.shared.pendingLevelUp {
                LevelUpOverlay(level: lvl, coins: XPStore.shared.pendingLevelUpCoins) {
                    XPStore.shared.consumeLevelUp()
                }
                .zIndex(60)
                .transition(.opacity)
            }
            if let m = ProgressStore.shared.pendingStreakMilestone {
                let r = ProgressStore.streakReward(forMilestone: m)
                StreakMilestoneOverlay(days: m, coins: r.coins, gems: r.gems) {
                    WalletStore.shared.earn(.coin, amount: r.coins)
                    if r.gems > 0 { WalletStore.shared.earn(.gem, amount: r.gems) }
                    _ = ProgressStore.shared.consumeStreakMilestone()
                }
                .zIndex(60)
                .transition(.opacity)
            }
            if let packId = PackRewardStore.shared.pendingCompletedPack {
                let title = MockData.allPacks.first { $0.id == packId }?.localizedTitle ?? ""
                PackCompleteOverlay(
                    packTitle: title,
                    coins: PackRewardStore.reward.coins,
                    gems: PackRewardStore.reward.gems
                ) {
                    PackRewardStore.shared.collect()
                    ChestStore.shared.addKey(2)   // finishing a pack drops 2 chest keys
                    maybeRequestReview()
                }
                .zIndex(65)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: chestReward?.id)
        .animation(.easeInOut(duration: 0.2), value: showSpin)
        .animation(.easeInOut(duration: 0.2), value: PackRewardStore.shared.pendingCompletedPack)
    }

    /// Ask for an App Store review at a genuine high point (pack completed),
    /// once ever, and only after enough engagement. Apple throttles the prompt.
    private func maybeRequestReview() {
        guard !hasRequestedReview,
              ProgressStore.shared.totalLevelsCompleted() >= 8 else { return }
        hasRequestedReview = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1400))   // let the reward settle
            requestReview()
        }
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
                topRow.appearStagger(0)             // greeting + today's quests + Zen toggle
                topStatsBar.appearStagger(1)        // energy · streak · level · progress
                if zenMode {
                    // Zen Mode on → ONLY the Zen entry is shown (calm focus).
                    zenCard.appearStagger(2)
                } else {
                    continueSection.appearStagger(2)    // CAMPAIGN — main progression, on top
                    gameModesHeader.appearStagger(3)
                    dailyPuzzleCard.appearStagger(4)
                    zenCard.appearStagger(5)            // relaxed entry (free, no energy)
                    towerCard.appearStagger(6)          // ticket-gated one-mistake climb
                    nookCard.appearStagger(7)           // cozy meta — decorate + rescue friends
                    questsCard.appearStagger(8)
                    weeklyCard.appearStagger(9)
                }
                Spacer(minLength: 96)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
        }
        .id(completedCount)
        .task { await DailyReminderService.shared.refreshAuthorizationState() }
        .onAppear {
            ProgressStore.shared.refreshPlayStreak()
            DailyQuestStore.shared.refresh()
            WeeklyChallengeStore.shared.refresh()
        }
    }

    // MARK: — Compact top stats bar (streak · level · progress)

    private func statSeg(_ icon: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
            Text(verbatim: value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.onSurface)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    /// Like `statSeg` but with the illustrated currency icon (gem / gold coin).
    private func currencySeg(_ currency: Currency, _ amount: Int) -> some View {
        HStack(spacing: 3) {
            CurrencyIcon(currency: currency, size: 16)
            Text(verbatim: "\(amount)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.onSurface)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(amount) " + NSLocalizedString(currency.displayNameKey, comment: "")))
    }

    /// A slim, warm "today" greeting + count of quests completed today. Kept
    /// intentionally light (one row) to honour the decluttered menu.
    private var todayBanner: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: LocalizedStringKey =
            hour < 6  ? "today.greeting.night" :
            hour < 12 ? "today.greeting.morning" :
            hour < 18 ? "today.greeting.afternoon" : "today.greeting.evening"
        let questsDone = (0..<3).filter { DailyQuestStore.shared.isComplete($0) }.count
        return HStack(spacing: AppSpacing.sm) {
            Text(greeting)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
            Spacer(minLength: AppSpacing.sm)
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .semibold))
                Text(verbatim: "\(questsDone)/3")
                    .font(AppTypography.labelSmall)
                    .monospacedDigit()
            }
            .foregroundStyle(questsDone == 3 ? AppColors.successGreen : AppColors.onSurfaceVariant)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .frame(maxWidth: .infinity)
        .background(AppColors.surfaceContainerLow, in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var topStatsBar: some View {
        let energyText = StoreManager.shared.isPremium ? "∞" : "\(EnergyStore.shared.current)/\(EnergyStore.maxEnergy)"
        let gems = WalletStore.shared.balance(of: .gem)
        let coins = WalletStore.shared.balance(of: .coin)
        func divider() -> some View {
            Capsule().fill(AppColors.surfaceContainerHigh).frame(width: 1.5, height: 22)
        }
        // Level-progress count moved into the Continue card ("Level N/total").
        return HStack(spacing: 0) {
            statSeg("bolt.fill", energyText, AppColors.tertiary)
            divider()
            currencySeg(.gem, gems)
            divider()
            currencySeg(.coin, coins)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.sm)
        .background(AppColors.surfaceContainer)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.5), AppColors.shadowAmbient.opacity(0.2)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1.5
            )
        )
        .shadowL1()
        .accessibilityElement(children: .combine)
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
        .accessibilityLabel(Text(verbatim: lit
            ? String(format: NSLocalizedString("a11y.playStreak", comment: ""), streak, best)
            : NSLocalizedString("a11y.noStreak", comment: "")))
    }

    // MARK: — Weekly Challenge card

    private var weeklyCard: some View {
        let store = WeeklyChallengeStore.shared
        let c = store.challenge
        let prog = min(store.progress, c.goal)
        let frac = c.goal > 0 ? CGFloat(prog) / CGFloat(c.goal) : 0
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.tertiary)
                Text("weekly.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                HStack(spacing: 4) {
                    CurrencyIcon(currency: .coin, size: 16)
                    Text(verbatim: "\(c.rewardCoins)")
                        .font(AppTypography.numericSmall).monospacedDigit()
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.8))
                    if c.rewardGems > 0 {
                        CurrencyIcon(currency: .gem, size: 16)
                        Text(verbatim: "\(c.rewardGems)")
                            .font(AppTypography.numericSmall).monospacedDigit()
                            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xs)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(verbatim: String(format: NSLocalizedString("weekly.goal", comment: ""), c.goal))
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                HStack(spacing: AppSpacing.sm) {
                    GameProgressBar(progress: Double(frac), height: 10, tint: AppColors.tertiary)
                    if store.canClaim {
                        claimChip {
                            if store.claim() != nil {
                                HapticService.shared.notify(.success)
                                SoundService.shared.play(.place)
                            }
                        }
                    } else {
                        Text(verbatim: store.claimed ? "✓" : "\(prog)/\(c.goal)")
                            .font(AppTypography.numericSmall).monospacedDigit()
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }
            }
            .infoCard()
        }
    }

    // MARK: — Endless Zen card

    private var endlessCard: some View {
        let best = EndlessStore.shared.best
        return Button {
            router.push(.game(levelID: "endless-1"))
        } label: {
            HStack(spacing: AppSpacing.md) {
                CardIconBadge(symbol: "infinity", tint: AppColors.primary, bg: AppColors.blockSage)
                VStack(alignment: .leading, spacing: 2) {
                    Text("endless.title")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text(verbatim: best > 0
                         ? String(format: NSLocalizedString("endless.best", comment: ""), best)
                         : NSLocalizedString("endless.subtitle", comment: ""))
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("button.menu.endless")
    }

    /// Shared "claim" chip — consistent type, spacing & shape for quests/weekly.
    private func claimChip(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("quest.claim")
                .font(AppTypography.labelSmall).tracking(0.4)
                .foregroundStyle(AppColors.primary)
                .padding(.horizontal, AppSpacing.sm).padding(.vertical, AppSpacing.xs)
                .background(AppColors.primaryContainer.opacity(0.5), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: — Energy meter + Zen entry + Rewards FAB

    private var isMenuTab: Bool {
        switch router.selectedTab {
        case .play, .home, .levels, .leaderboard: return true
        default: return false
        }
    }

    /// Top row: the greeting banner + a corner Zen toggle (was buried in Settings).
    private var topRow: some View {
        HStack(spacing: AppSpacing.sm) {
            todayBanner
            zenToggle
        }
    }

    /// Corner Zen toggle. On → app shifts to the sage palette (RootView rebuilds)
    /// and the home shows only the Zen entry.
    private var zenToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { zenMode.toggle() }
            HapticService.shared.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: zenMode ? "leaf.fill" : "leaf")
                    .font(.system(size: 13, weight: .bold))
                Text(verbatim: "Zen")
                    .font(AppTypography.labelSmall)
            }
            .foregroundStyle(zenMode ? AppColors.onPrimary : AppColors.onSurfaceVariant)
            .padding(.horizontal, AppSpacing.sm + 2)
            .padding(.vertical, 9)
            .background(zenMode ? AppColors.primary : AppColors.surfaceContainerLow, in: Capsule())
            .overlay(Capsule().stroke(zenMode ? .clear : AppColors.surfaceContainerHigh, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("zen.mode.title"))
        .accessibilityValue(Text(zenMode ? "On" : "Off"))
    }

    /// "Game Modes" section header (Daily / Zen / Tower live below it).
    private var gameModesHeader: some View {
        Text("menu.gameModes")
            .font(AppTypography.headlineSmall)
            .foregroundStyle(AppColors.onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.top, AppSpacing.xs)
    }

    /// Cozy meta entry — decorate your Nook + rescue the friends you free by
    /// completing campaign packs. Shows how "cozy" (complete) the Nook is.
    private var nookCard: some View {
        let pct = Int((NookStore.shared.completion * 100).rounded())
        let ready = NookStore.shared.totalAvailablePieces
        return Button { router.push(.nook) } label: {
            HStack(spacing: AppSpacing.md) {
                CardIconBadge(symbol: "house.fill", tint: AppColors.tertiary, bg: AppColors.blockCream)
                VStack(alignment: .leading, spacing: 2) {
                    Text("nook.title")
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Text("nook.subtitle")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: ready > 0 ? "puzzlepiece.fill" : "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    if ready > 0 {
                        Text(verbatim: "\(ready)")
                            .font(AppTypography.numericSmall).monospacedDigit()
                    } else {
                        Text(verbatim: String(format: NSLocalizedString("nook.cozy.percent", comment: ""), pct))
                            .font(AppTypography.numericSmall).monospacedDigit()
                    }
                }
                .foregroundStyle(ready > 0 ? AppColors.onTertiary : AppColors.tertiary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 5)
                .background(ready > 0 ? AppColors.tertiary : AppColors.surfaceContainerHigh, in: Capsule())
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("button.menu.nook")
    }

    /// Prominent Zen entry — relaxed, no timer, FREE (never costs energy).
    private var zenCard: some View {
        Button { router.push(.game(levelID: "endless-1")) } label: {
            HStack(spacing: AppSpacing.md) {
                CardIconBadge(symbol: "leaf.fill", tint: AppColors.primary, bg: AppColors.blockSage)
                VStack(alignment: .leading, spacing: 2) {
                    Text("zen.mode.title")
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Text("zen.mode.subtitle")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("button.menu.zen")
    }

    /// Tower entry — ticket-gated, one-mistake climb. Tap with no ticket → Shop
    /// (where gems convert to tickets).
    private var towerCard: some View {
        let best = TowerStore.shared.bestFloor
        return Button {
            let tower = TowerStore.shared
            if tower.hasActiveRun {
                // Resume the in-progress climb where you left off — no ticket.
                router.push(.game(levelID: "tower-\(tower.currentFloor)"))
            } else if tower.payEntry() {
                tower.setCurrentFloor(1)
                router.push(.game(levelID: "tower-1"))
            } else {
                showTowerNoTicket = true
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                CardIconBadge(symbol: "building.2.fill", tint: AppColors.secondary, bg: AppColors.blockBlush)
                VStack(alignment: .leading, spacing: 2) {
                    Text("tower.title")
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Group {
                        if TowerStore.shared.hasActiveRun {
                            Text(verbatim: String(format: NSLocalizedString("tower.resume", comment: ""), TowerStore.shared.currentFloor))
                        } else if best > 0 {
                            Text(verbatim: String(format: NSLocalizedString("tower.best", comment: ""), best))
                        } else {
                            Text("tower.subtitle")
                        }
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                }
                Spacer()
                // Player's ticket balance (tickets are Tower-only, so this is the
                // natural place to show how many you have).
                HStack(spacing: 4) {
                    CurrencyIcon(currency: .ticket, size: 18)
                    Text(verbatim: "\(WalletStore.shared.ticket)")
                        .font(AppTypography.numericLabel).monospacedDigit()
                }
                .foregroundStyle(AppColors.tertiary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 5)
                .background(AppColors.surfaceContainerHigh, in: Capsule())
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("button.menu.tower")
    }

    /// Floating rewards button + drop-down (spin / daily / chest).
    private var rewardsFab: some View {
        let anyAvailable = SpinStore.shared.canSpin
            || DailyCalendarStore.shared.canClaim
            || ChestStore.shared.canOpen
        return VStack(alignment: .trailing, spacing: AppSpacing.sm) {
            if showRewardsMenu {
                VStack(spacing: AppSpacing.xs) {
                    rewardTile(icon: "dial.medium.fill", titleKey: "spin.title", available: SpinStore.shared.canSpin) {
                        showRewardsMenu = false
                        if SpinStore.shared.canSpin { showSpin = true }
                    }
                    rewardTile(icon: "calendar", titleKey: "calendar.title", available: DailyCalendarStore.shared.canClaim) {
                        showRewardsMenu = false
                        showCalendar = true
                    }
                    rewardTile(icon: "shippingbox.fill", assetIcon: "Chest",
                               titleKey: "chest.title", available: ChestStore.shared.canOpen,
                               keyCount: ChestStore.shared.keys) {
                        showRewardsMenu = false
                        if let r = ChestStore.shared.open() { chestReward = r }
                    }
                }
                .padding(AppSpacing.sm)
                .frame(width: 128)
                .background(AppColors.surfaceContainerLowest,
                            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .cardSurface()
                .transition(.scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity))
            }
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { showRewardsMenu.toggle() }
            } label: {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 48, height: 48)
                    // Icon centered via overlay (NOT a ZStack alignment, which
                    // would shove it off-centre).
                    .overlay(
                        Image(systemName: showRewardsMenu ? "xmark" : "gift.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.onPrimary)
                    )
                    // Availability dot — separate overlay so it never moves the icon.
                    .overlay(alignment: .topTrailing) {
                        if anyAvailable && !showRewardsMenu {
                            Circle().fill(AppColors.tertiary).frame(width: 12, height: 12)
                                .overlay(Circle().stroke(AppColors.background, lineWidth: 2))
                                .offset(x: 2, y: -2)
                        }
                    }
                    .shadowL2()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("rewards.fab"))
        }
    }

    // MARK: — Rewards rail (spin · calendar · chest)

    private func rewardTile(icon: String, assetIcon: String? = nil, titleKey: LocalizedStringKey,
                            available: Bool, keyCount: Int? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.primaryContainer.opacity(available ? 0.5 : 0.25))
                            .frame(width: 52, height: 52)
                        if let assetIcon {
                            Image(assetIcon)
                                .resizable().renderingMode(.original).scaledToFit()
                                .frame(width: 36, height: 36)
                                .opacity(available ? 1 : 0.5)
                                .saturation(available ? 1 : 0.3)
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(available ? AppColors.primary : AppColors.onSurfaceVariant)
                        }
                    }
                    if available {
                        Circle().fill(AppColors.tertiary)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(AppColors.background, lineWidth: 2))
                            .offset(x: 4, y: -4)
                    }
                    // Key count badge (chest tile) — shows how many keys you hold.
                    if let keyCount {
                        HStack(spacing: 1) {
                            Image("Key").resizable().renderingMode(.original).scaledToFit()
                                .frame(width: 11, height: 11)
                            Text(verbatim: "\(keyCount)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.onSurface)
                        }
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(AppColors.surfaceContainerHigh, in: Capsule())
                        .offset(x: 8, y: -6)
                    }
                }
                Text(titleKey)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var rewardsRail: some View {
        HStack(spacing: AppSpacing.xs) {
            rewardTile(icon: "dial.medium.fill", titleKey: "spin.title", available: SpinStore.shared.canSpin) {
                if SpinStore.shared.canSpin { showSpin = true }
            }
            rewardTile(icon: "calendar", titleKey: "calendar.title", available: DailyCalendarStore.shared.canClaim) {
                showCalendar = true
            }
            rewardTile(icon: "shippingbox.fill", assetIcon: "Chest",
                       titleKey: "chest.title", available: ChestStore.shared.canOpen,
                       keyCount: ChestStore.shared.keys) {
                if let r = ChestStore.shared.open() { chestReward = r }
            }
        }
        .padding(.horizontal, AppSpacing.xs)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .cardSurface()
        .accessibilityIdentifier("menu.rewardsRail")
    }

    // MARK: — Daily Reward Calendar card

    @ViewBuilder
    private var calendarCard: some View {
        let available = DailyCalendarStore.shared.canClaim
        Button { showCalendar = true } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.tertiaryContainer.opacity(available ? 0.5 : 0.25))
                        .frame(width: 48, height: 48)
                    Image(systemName: "calendar")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(available ? AppColors.primary : AppColors.onSurfaceVariant)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("calendar.title")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text(available ? "calendar.available" : "calendar.comeBack")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(available ? AppColors.primary : AppColors.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(available ? AppColors.primary : AppColors.onSurfaceVariant.opacity(0.5))
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(available ? AppColors.primary.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("button.menu.calendar")
    }

    // MARK: — Daily Spin card

    @ViewBuilder
    private var spinCard: some View {
        let available = SpinStore.shared.canSpin
        Button {
            if SpinStore.shared.canSpin { showSpin = true }
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.primaryContainer.opacity(available ? 0.5 : 0.25))
                        .frame(width: 48, height: 48)
                    Image(systemName: "dial.medium.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(available ? AppColors.primary : AppColors.onSurfaceVariant)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("spin.title")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text(available ? "spin.available" : "spin.comeBack")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(available ? AppColors.primary : AppColors.onSurfaceVariant)
                }
                Spacer()
                if available {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .cardSurface()
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(available ? AppColors.primary.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .accessibilityIdentifier("button.menu.spin")
    }

    // MARK: — Reward Chest card

    @ViewBuilder
    private func chestCardBody(ready: Bool) -> some View {
        let store = ChestStore.shared
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.tertiary.opacity(ready ? 0.22 : 0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: ready ? "gift.fill" : "shippingbox.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.tertiary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ready ? "chest.ready" : "chest.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                if ready {
                    Text("chest.tapToOpen")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                } else {
                    GameProgressBar(
                        progress: Double(store.progress) / Double(max(store.goal, 1)),
                        height: 10, tint: AppColors.tertiary
                    )
                }
            }
            Spacer()
            Text(verbatim: ready ? "×\(store.pending)" : "\(store.progress)/\(store.goal)")
                .font(AppTypography.numericSmall)
                .monospacedDigit()
                .foregroundStyle(ready ? AppColors.tertiary : AppColors.onSurfaceVariant)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .cardSurface()
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(ready ? AppColors.tertiary.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private var chestCard: some View {
        let store = ChestStore.shared
        if store.hasChest {
            Button {
                if let r = store.open() { chestReward = r }
            } label: {
                chestCardBody(ready: true)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("button.menu.chest")
        } else {
            chestCardBody(ready: false)
                .accessibilityElement(children: .combine)
        }
    }

    // MARK: — Daily Quests card

    private func questTitle(_ q: DailyQuest) -> String {
        switch q.kind {
        case .solveLevels:
            return String(format: NSLocalizedString("quest.solveLevels", comment: ""), q.goal)
        case .solveUnder:
            return String(format: NSLocalizedString("quest.solveUnder", comment: ""), q.param)
        case .noHintSolves:
            return String(format: NSLocalizedString("quest.noHints", comment: ""), q.goal)
        case .perfectSolve:
            return String(format: NSLocalizedString("quest.perfect", comment: ""), q.goal)
        }
    }

    @ViewBuilder
    private func questRow(_ q: DailyQuest, index: Int) -> some View {
        let store = DailyQuestStore.shared
        let prog = min(store.progress[index], q.goal)
        let frac = q.goal > 0 ? CGFloat(prog) / CGFloat(q.goal) : 0
        let claimed = store.claimed[index]
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: q.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(claimed ? AppColors.onSurfaceVariant.opacity(0.5) : AppColors.primary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: questTitle(q))
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(claimed ? AppColors.onSurfaceVariant : AppColors.onSurface)
                    .strikethrough(claimed, color: AppColors.onSurfaceVariant)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppColors.surfaceContainerHigh).frame(height: 6)
                        Capsule().fill(AppColors.primary).frame(width: geo.size.width * frac, height: 6)
                    }
                }
                .frame(height: 6)
            }

            VStack(alignment: .trailing, spacing: 2) {
                if store.canClaim(index) {
                    claimChip {
                        if DailyQuestStore.shared.claim(index) != nil {
                            HapticService.shared.notify(.success)
                            SoundService.shared.play(.place)
                        }
                    }
                } else if claimed {
                    Label("quest.claimed", systemImage: "checkmark")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
                        .labelStyle(.titleOnly)
                } else {
                    Text(verbatim: "\(prog)/\(q.goal)")
                        .font(AppTypography.numericSmall)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                HStack(spacing: 3) {
                    if q.rewardGems > 0 {
                        CurrencyIcon(currency: .gem, size: 14)
                        Text(verbatim: "\(q.rewardGems)")
                            .font(AppTypography.numericSmall).monospacedDigit()
                            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
                    } else {
                        CurrencyIcon(currency: .coin, size: 14)
                        Text(verbatim: "\(q.rewardCoins)")
                            .font(AppTypography.numericSmall).monospacedDigit()
                            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }

    private var questsCard: some View {
        let store = DailyQuestStore.shared
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.primary)
                Text("quest.header")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(store.quests.enumerated()), id: \.element.id) { idx, q in
                    questRow(q, index: idx)
                    if idx < store.quests.count - 1 {
                        Divider().background(AppColors.surfaceContainerHigh)
                    }
                }
            }
            .infoCard()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.progress)
    }

    // MARK: — Progress pill

    private var progressPill: some View {
        let completed = ProgressStore.shared.totalLevelsCompleted()
        let total = MockData.totalLevels
        let current = min(completed + 1, total)
        return HStack(spacing: AppSpacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.tertiary)
                .accessibilityHidden(true)

            Text(verbatim: String(format: NSLocalizedString("level.label", comment: ""), current))
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
            Capsule().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.5), AppColors.shadowAmbient.opacity(0.2)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1.5
            )
        )
        .clipShape(Capsule())
        .shadowL1()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.continueStats", comment: ""), current, total, completed)))
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
            .task(id: dailyIsComplete) {
                // Defer the ImageRenderer pass so it never janks the menu render.
                try? await Task.sleep(for: .milliseconds(400))
                renderDailyShare()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("button.menu.dailyPuzzle")
    }

    /// Render the shareable daily-streak card to an image when the daily is done.
    @MainActor
    private func renderDailyShare() {
        guard dailyIsComplete else { dailyShareImage = nil; return }
        let card = DailyShareCard(
            streak: ProgressStore.shared.currentStreak,
            daysSolved: ProgressStore.shared.dailyResults.filter(\.solved).count,
            dateText: dailyDateBadge
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let ui = renderer.uiImage { dailyShareImage = Image(uiImage: ui) }
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

                // Share the daily-streak card once today's daily is complete.
                if dailyIsComplete, let img = dailyShareImage {
                    ShareLink(item: img,
                              preview: SharePreview("daily.share.title", image: img)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(AppColors.surfaceContainerHigh))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("daily.share.title"))
                }

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
                .accessibilityLabel(Text("a11y.viewAllPacks"))
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
                .accessibilityHint(Text("a11y.startFirstHint"))
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
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: String(
            format: NSLocalizedString("a11y.continueCard", comment: ""),
            pack.localizedTitle, level.number, Int(pack.progressFraction * 100)
        )))
        .accessibilityHint(Text("a11y.continueHint"))
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
                    Text(pack.titleKey)
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                        .lineLimit(1)

                    // Global level position out of all campaign levels (e.g. 12/1020).
                    // level.number is pack-relative, so add the levels in earlier packs.
                    let globalNumber = MockData.allPacks
                        .prefix(while: { $0.id != pack.id })
                        .reduce(0) { $0 + $1.levelCount } + level.number
                    Text(verbatim: String(
                        format: NSLocalizedString("level.labelTotal", comment: ""),
                        globalNumber, MockData.totalLevels
                    ))
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
