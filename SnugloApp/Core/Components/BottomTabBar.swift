import SwiftUI

// MARK: — BottomTabBar
// Shared bottom navigation bar — appears on Play/Levels/Stats/Shop screens.
// Design reference: 03-main-menu.html, 04-levels-list.html bottom nav.
//
// Active tab: lavender pill background + filled icon
// Inactive tab: secondary color + outline icon

struct BottomTabBar: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)       // above safe area
        .background(AppColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous).inset(by: -1))
        .shadow(color: AppColors.shadowAmbient.opacity(0.06), radius: 12, x: 0, y: -4)
    }

    // MARK: — Individual tab button

    private func tabButton(_ tab: AppTab) -> some View {
        let isActive = router.selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                router.selectTab(tab)
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: tab.sfSymbol)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.monochrome)

                Text(tab.rawValue)
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
            }
            .foregroundStyle(isActive ? AppColors.primary : AppColors.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                isActive
                    ? AppColors.primaryContainer.opacity(0.5)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: — Preview

#Preview {
    let router = AppRouter()
    return VStack {
        Spacer()
        BottomTabBar()
    }
    .environment(router)
    .background(AppColors.background)
}
