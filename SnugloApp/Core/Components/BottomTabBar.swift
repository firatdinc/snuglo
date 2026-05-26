import SwiftUI

// MARK: — BottomTabBar (H-1: Localized · Faz I-2: updated tabs & identifiers)
// Ref: Designs/html/03-main-menu.html (nav section)
// Faz I-2: 4 tabs — Home · Stats · Shop · Settings
//          Identifiers: tab.home / tab.stats / tab.shop / tab.settings
// Active tab: lavender pill background + filled icon.
//
// Reads and writes router.selectedTab via @Environment so call sites
// need no @Binding passthrough — just BottomTabBar() with no args.

struct BottomTabBar: View {

    @Environment(AppRouter.self) private var router

    private struct TabItem {
        let tab: AppTab
        let labelKey: LocalizedStringKey
        let icon: String
        let activeIcon: String
        let a11yId: String
    }

    private let items: [TabItem] = [
        .init(tab: .home, labelKey: "tab.home", icon: "house", activeIcon: "house.fill", a11yId: "tab.home"),
        .init(tab: .stats, labelKey: "tab.stats", icon: "chart.bar", activeIcon: "chart.bar.fill", a11yId: "tab.stats"),
        .init(tab: .shop, labelKey: "tab.shop", icon: "bag", activeIcon: "bag.fill", a11yId: "tab.shop"),
        .init(tab: .settings, labelKey: "tab.settings", icon: "gearshape", activeIcon: "gearshape.fill", a11yId: "tab.settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                Button {
                    router.selectTab(item.tab)
                } label: {
                    VStack(spacing: AppSpacing.xs - 2) {
                        Image(systemName: router.selectedTab == item.tab ? item.activeIcon : item.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(router.selectedTab == item.tab ? AppColors.onPrimaryContainer : AppColors.secondary)

                        Text(item.labelKey)
                            .font(AppTypography.labelSmall)
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .foregroundStyle(router.selectedTab == item.tab ? AppColors.onPrimaryContainer : AppColors.secondary)
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                    .background(
                        router.selectedTab == item.tab
                            ? AppColors.primaryContainer
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: AppRadius.block + 2, style: .continuous)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: router.selectedTab)
                .accessibilityIdentifier(item.a11yId)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
        .background(
            AppColors.surface
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.outlineVariant.opacity(0.2))
                        .frame(height: 0.5)
                }
        )
        .shadowL1()
    }
}

#Preview {
    VStack {
        Spacer()
        BottomTabBar()
    }
    .background(AppColors.background)
    .environment(AppRouter())
}
