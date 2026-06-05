import SwiftUI

// MARK: — ProfileView (Faz 6)
// Identity card + premium status + quick links (Achievements / Best Scores / Daily Reward / Stats).
// Settings is a backward-compat tab switch (existing behaviour preserved).

struct ProfileView: View {

    @Environment(AppRouter.self) private var router
    private var gcState: GameCenterAuthState { GameCenterManager.shared.authState }
    private var isPremium: Bool { StoreManager.shared.isPremium }
    private var cupBalance: Int { WalletStore.shared.balance(of: .cup) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                identityCard
                xpCard
                premiumCard
                quickLinksSection
                settingsRow
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background.ignoresSafeArea())
        // Consistent with all other tab roots — hidden root nav bar so the `.page`
        // TabView never has mismatched nav bars across pages during a swipe.
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.profile")
    }

    // MARK: — XP / Level card

    private var xpCard: some View {
        let xp = XPStore.shared
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle().fill(AppColors.primaryContainer).frame(width: 40, height: 40)
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)
                Text(verbatim: String(format: NSLocalizedString("level.label", comment: ""), xp.level))
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                Text(verbatim: "\(xp.xpIntoLevel) / \(xp.xpForNext) XP")
                    .font(AppTypography.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            GameProgressBar(progress: Double(xp.progress), height: 14)
        }
        .infoCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(xp.level), \(xp.xpIntoLevel) of \(xp.xpForNext) XP")
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
                    router.showPaywall = true
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
