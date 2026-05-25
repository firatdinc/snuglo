import SwiftUI

// MARK: — BottomTabBar
// Ref: Designs/html/03-main-menu.html (nav section)
// 4-tab custom bottom bar: Play · Levels · Stats · Shop
// Active tab: lavender pill background + filled icon.
//
// Reads and writes router.selectedTab via @Environment so call sites
// need no @Binding passthrough — just BottomTabBar() with no args.

struct BottomTabBar: View {

    @Environment(AppRouter.self) private var router

    private struct TabItem {
        let tab: AppTab
        let label: String
        let icon: String
        let activeIcon: String
    }

    private let items: [TabItem] = [
        .init(tab: .play,   label: "Play",   icon: "puzzlepiece",       activeIcon: "puzzlepiece.fill"),
        .init(tab: .levels, label: "Levels", icon: "square.grid.2x2",   activeIcon: "square.grid.2x2.fill"),
        .init(tab: .stats,  label: "Stats",  icon: "chart.bar",         activeIcon: "chart.bar.fill"),
        .init(tab: .shop,   label: "Shop",   icon: "bag",               activeIcon: "bag.fill")
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

                        Text(item.label)
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
