import SwiftUI

// MARK: — RootTabView (Faz 1: 5-tab custom bar)
// Tab order (left → right): Levels · Shop · [Play] · Leaderboard · Profile
// • Custom bar overlay: elevated centre Play button, 2 items each side
// • hideBar: slides bar off on any tab NavigationStack push (spring animated)
// • iOS 26 observation fix: per-path @State arrays trigger reliable hideBar re-renders
//   (typed [Route] arrays vs NavigationPath — avoids fresh-launch observation glitch)

struct RootTabView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hideBar: Bool = false

    private var anyTabPushed: Bool {
        !router.levelsPath.isEmpty || !router.shopPath.isEmpty      ||
        !router.playPath.isEmpty   || !router.leaderboardPath.isEmpty ||
        !router.profilePath.isEmpty
    }

    private func computeShouldHide() -> Bool { anyTabPushed }

    private let barHeight: CGFloat = 80

    private var deviceSafeBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom }
            .first ?? 0
    }

    var body: some View {
        @Bindable var bindableRouter = router
        // Explicit reads register @Observable deps so body re-renders when
        // paths change. $bindableRouter.xPath only creates Bindings (lazy gets)
        // and does NOT register deps on the underlying properties by itself.
        // swiftlint:disable redundant_discardable_let
        let _ = router.levelsPath
        let _ = router.shopPath
        let _ = router.playPath
        let _ = router.leaderboardPath
        let _ = router.profilePath
        let _ = router.selectedTab
        // swiftlint:enable redundant_discardable_let
        let safeBottom = deviceSafeBottom
        let contentInset: CGFloat = hideBar ? 0 : (barHeight + safeBottom)

        TabView(selection: $bindableRouter.selectedTab) {
            NavigationStack(path: $bindableRouter.levelsPath) {
                LevelsListView(packId: "")
                    .navigationBarBackButtonHidden()
                    .navigationDestination(for: Route.self) { tabDestination($0) }
            }
            .tag(AppTab.levels)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack(path: $bindableRouter.shopPath) {
                ShopView()
                    .navigationBarBackButtonHidden()
                    .navigationDestination(for: Route.self) { tabDestination($0) }
            }
            .tag(AppTab.shop)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack(path: $bindableRouter.playPath) {
                MainMenuView()
                    .navigationBarBackButtonHidden()
                    .navigationDestination(for: Route.self) { tabDestination($0) }
            }
            .tag(AppTab.play)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack(path: $bindableRouter.leaderboardPath) {
                LeaderboardView()
                    .navigationBarBackButtonHidden()
                    .navigationDestination(for: Route.self) { tabDestination($0) }
            }
            .tag(AppTab.leaderboard)
            .toolbar(.hidden, for: .tabBar)

            NavigationStack(path: $bindableRouter.profilePath) {
                ProfileView()
                    .navigationBarBackButtonHidden()
                    .navigationDestination(for: Route.self) { tabDestination($0) }
            }
            .tag(AppTab.profile)
            .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: contentInset)
        }
        .overlay(alignment: .bottom) {
            CustomTabBar(
                selected: $bindableRouter.selectedTab,
                safeBottom: safeBottom
            ) { tab in
                onTabTap(tab)
            }
            .offset(y: hideBar ? (barHeight + safeBottom + 40) : 0)
            .opacity(hideBar ? 0 : 1)
            .allowsHitTesting(!hideBar)
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.85),
            value: hideBar
        )
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Per-path onChange forces reliable hideBar refresh on the very first push
        // after a cold launch — a direct computed-property read inside body is not
        // sufficient on iOS 26 TabView trees.
        .onChange(of: router.levelsPath) { _, _ in hideBar = computeShouldHide() }
        .onChange(of: router.shopPath) { _, _ in hideBar = computeShouldHide() }
        .onChange(of: router.playPath) { _, _ in hideBar = computeShouldHide() }
        .onChange(of: router.leaderboardPath) { _, _ in hideBar = computeShouldHide() }
        .onChange(of: router.profilePath) { _, _ in hideBar = computeShouldHide() }
        .onAppear { hideBar = computeShouldHide() }
    }

    // MARK: — Destination routing (shared across all tabs)

    @ViewBuilder
    private func tabDestination(_ route: Route) -> some View {
        switch route {
        case .game(let levelID):
            GameView(levelId: levelID)
                .id(levelID)
                .navigationBarBackButtonHidden()
        case .gamePlay(let levelId):
            GameView(levelId: levelId)
                .id(levelId)
                .navigationBarBackButtonHidden()
        case .packDetail(let packId):
            PackDetailView(packName: packId)
        case .settings:
            SettingsView()
        case .shop:
            ShopView()
        case .levelsList:
            LevelsListView(packId: "")
        case .mainMenu, .onboarding:
            EmptyView()
        }
    }

    // MARK: — Tab selection

    private func onTabTap(_ tab: AppTab) {
        HapticService.shared.impact(.light)
        router.selectTab(tab)
    }
}

// MARK: — CustomTabBar

private struct CustomTabBar: View {

    @Binding var selected: AppTab
    let safeBottom: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onSelect: (AppTab) -> Void

    private struct TabItem {
        let tab: AppTab
        let labelKey: LocalizedStringKey
        let icon: String
        let a11yId: String
    }

    private let leftItems: [TabItem] = [
        .init(tab: .levels, labelKey: "tab.levels", icon: "map.fill", a11yId: "tab.levels"),
        .init(tab: .shop, labelKey: "tab.shop", icon: "bag.fill", a11yId: "tab.shop")
    ]
    private let rightItems: [TabItem] = [
        .init(tab: .leaderboard, labelKey: "tab.leaderboard", icon: "trophy.fill", a11yId: "tab.leaderboard"),
        .init(tab: .profile, labelKey: "tab.profile", icon: "person.crop.circle.fill", a11yId: "tab.profile")
    ]

    private let barIconHeight: CGFloat = 80

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    ForEach(leftItems, id: \.tab) { tabButton($0) }
                    Color.clear.frame(width: 76) // gap for centre button
                    ForEach(rightItems, id: \.tab) { tabButton($0) }
                }
                .frame(maxWidth: .infinity)

                centrePlayButton
                    .offset(y: -18)
            }
            .frame(height: barIconHeight)

            Color.clear.frame(height: safeBottom)
        }
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22,
                style: .continuous
            )
            .fill(AppColors.surfaceContainerLowest)
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 22,
                    style: .continuous
                )
                .strokeBorder(AppColors.outlineVariant.opacity(0.4), lineWidth: 0.5)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: AppColors.shadowAmbient.opacity(0.08), radius: 12, x: 0, y: -4)
    }

    // MARK: — Centre Play button

    private var centrePlayButton: some View {
        let isActive = (selected == .play)
        return Button { onSelect(.play) } label: {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(isActive ? AppColors.onPrimary : AppColors.primary)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(isActive ? AppColors.primary : AppColors.primaryContainer)
                        .shadow(
                            color: AppColors.primary.opacity(isActive ? 0.45 : 0.2),
                            radius: 10, y: 4
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(
            reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.65),
            value: selected
        )
        .accessibilityLabel(Text("tab.play"))
        .accessibilityIdentifier("tab.play")
    }

    // MARK: — Side tab button

    @ViewBuilder
    private func tabButton(_ item: TabItem) -> some View {
        let isActive = (selected == item.tab)
        Button { onSelect(item.tab) } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.outline)
                    .scaleEffect(isActive ? 1.05 : 1.0)

                Text(item.labelKey)
                    .font(AppTypography.labelSmall)
                    .tracking(0.4)
                    .foregroundStyle(isActive ? AppColors.primary : AppColors.outline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(
            reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7),
            value: selected
        )
        .accessibilityIdentifier(item.a11yId)
    }
}

#Preview {
    RootTabView()
        .environment(AppRouter())
}
