import SwiftUI

// MARK: — ProfileView (Faz 6)
// Identity card + premium status + quick links (Achievements / Best Scores / Daily Reward / Stats).
// Settings is a backward-compat tab switch (existing behaviour preserved).

struct ProfileView: View {

    @Environment(AppRouter.self) private var router
    private var gcState: GameCenterAuthState { GameCenterManager.shared.authState }
    private var isPremium: Bool { StoreManager.shared.adsRemoved }
    private var cupBalance: Int { WalletStore.shared.balance(of: .cup) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                identityCard
                premiumCard
                quickLinksSection
                settingsRow
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background.ignoresSafeArea())
        .accessibilityIdentifier("screen.profile")
    }

    // MARK: — Identity Card

    private var identityCard: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 60, height: 60)
                .background(AppColors.primaryContainer, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(gcDisplayName)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                    .lineLimit(1)

                Text("profile.subtitle")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()

            BalanceChip(currency: .cup, amount: cupBalance)
        }
        .padding(AppSpacing.md)
        .cardSurface()
    }

    private var gcDisplayName: String {
        if case .signedIn(let name) = gcState { return name }
        return NSLocalizedString("profile.identity.title", comment: "")
    }

    // MARK: — Premium Card

    private var premiumCard: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: isPremium ? "crown.fill" : "crown")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isPremium ? AppColors.secondary : AppColors.outline)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(isPremium ? "profile.premium.active" : "profile.premium.upgrade.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                if !isPremium {
                    Text("profile.premium.upgrade.subtitle")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }

            Spacer()

            if !isPremium {
                Button {
                    router.selectTab(.shop)
                } label: {
                    Text("common.upgrade")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .cardSurface()
    }

    // MARK: — Quick Links

    private var quickLinksSection: some View {
        VStack(spacing: 0) {
            quickLink(
                icon: "rosette",
                titleKey: "profile.link.achievements",
                accessibilityID: "profile.link.achievements"
            ) {
                router.push(.achievements)
            }

            RowDivider()

            quickLink(
                icon: "trophy.fill",
                titleKey: "profile.link.bestScores",
                accessibilityID: "profile.link.bestScores"
            ) {
                router.selectTab(.leaderboard)
            }

            RowDivider()

            quickLink(
                icon: "gift.fill",
                titleKey: "profile.link.dailyReward",
                accessibilityID: "profile.link.dailyReward"
            ) {
                router.push(.dailyReward)
            }

            RowDivider()

            NavigationLink(destination: StatsView()) {
                quickLinkContent(icon: "chart.bar.fill", titleKey: "profile.link.stats")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.link.stats")
        }
        .cardSurface()
    }

    @ViewBuilder
    private func quickLink(
        icon: String,
        titleKey: LocalizedStringKey,
        accessibilityID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            quickLinkContent(icon: icon, titleKey: titleKey)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
    }

    private func quickLinkContent(icon: String, titleKey: LocalizedStringKey) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text(titleKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.outline)
                .accessibilityHidden(true)
        }
        .padding(AppSpacing.md)
    }

    // MARK: — Settings Row

    private var settingsRow: some View {
        Button {
            router.selectTab(.settings)
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.outline)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                Text("profile.settings.title")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurface)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.outline)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.md)
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.settings")
    }
}

#Preview {
    ProfileView()
        .environment(AppRouter())
}
