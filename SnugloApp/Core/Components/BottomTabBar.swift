import SwiftUI

// MARK: — BottomTabBar (Vibrant Play — Play · Levels · Shop · Profile)
// Source: Designs/VibrantPlay/SPEC.md + main-menu.html
//   Play    → selectTab(.play)    — icon: gamecontroller      — id: tab.play
//   Levels  → push(.levelsList)   — icon: map                 — id: tab.levels
//   Shop    → selectTab(.shop)    — icon: bag                 — id: tab.shop
//   Profile → selectTab(.profile) — icon: person.crop.circle  — id: tab.profile
// Stats lives INSIDE the Profile tab (not a top-level tab anymore).
// Tab switches are non-animated (no NavigationStack push/pop slide) so moving
// between any two tabs feels consistent — fixes the reverse-slide on Levels↔X.
// Active state: AppColors.primary (blue) + filled icon.

struct BottomTabBar: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct TabItem {
        let tab: AppTab
        let labelKey: LocalizedStringKey
        let icon: String
        let activeIcon: String
        let a11yId: String
    }

    private let items: [TabItem] = [
        .init(tab: .play, labelKey: "tab.play", icon: "gamecontroller", activeIcon: "gamecontroller.fill", a11yId: "tab.play"),
        .init(tab: .levels, labelKey: "tab.levels", icon: "map", activeIcon: "map.fill", a11yId: "tab.levels"),
        .init(tab: .shop, labelKey: "tab.shop", icon: "bag", activeIcon: "bag.fill", a11yId: "tab.shop"),
        .init(tab: .profile, labelKey: "tab.profile", icon: "person.crop.circle", activeIcon: "person.crop.circle.fill", a11yId: "tab.profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                Button {
                    handleTap(item.tab)
                } label: {
                    tabItemLabel(item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(item.a11yId)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
        .background(
            AppColors.surfaceContainerLowest
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.outlineVariant.opacity(0.4))
                        .frame(height: 1)
                }
        )
        // Shadow casts upward (tab bar sits at screen bottom)
        .shadow(
            color: AppColors.shadowAmbient.opacity(0.08),
            radius: 12, x: 0, y: -4
        )
    }

    // MARK: — Tap handler

    private func handleTap(_ tab: AppTab) {
        // Disable the NavigationStack push/pop animation so switching to/from the
        // Levels tab is instant — same feel as the in-place tab switches. Without
        // this, Levels↔X slid in one direction and popped the other (reverse-slide).
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) {
            if tab == .levels {
                guard !router.path.contains(.levelsList) else { return }
                router.push(.levelsList)
            } else {
                if router.path.contains(.levelsList) { router.pop() }
                router.selectTab(tab)
            }
        }
    }

    // MARK: — Active state

    private func isActive(_ tab: AppTab) -> Bool {
        switch tab {
        case .play:
            let onPlayContent = router.selectedTab == .play || router.selectedTab == .home
            return onPlayContent && !router.path.contains(.levelsList)
        case .levels:
            return router.path.contains(.levelsList)
        case .shop:
            return router.selectedTab == .shop && !router.path.contains(.levelsList)
        case .profile:
            return router.selectedTab == .profile && !router.path.contains(.levelsList)
        default:
            return false
        }
    }

    // MARK: — Item label

    private func tabItemLabel(_ item: TabItem) -> some View {
        let active = isActive(item.tab)
        return VStack(spacing: 2) {
            Image(systemName: active ? item.activeIcon : item.icon)
                .font(.system(size: 22))
                .foregroundStyle(active ? AppColors.primary : AppColors.outline)
                .scaleEffect(active ? 1.05 : 1.0)

            Text(item.labelKey)
                .font(AppTypography.labelSmall)
                .tracking(0.4)
                .foregroundStyle(active ? AppColors.primary : AppColors.outline)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .contentShape(Rectangle())
        .animation(
            reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
            value: active
        )
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
