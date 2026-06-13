import SwiftUI

// MARK: — AchievementsView

struct AchievementsView: View {

    @State private var vm = AchievementsViewModel()
    @State private var selectedAchievement: Achievement?

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                progressHeader
                    .padding(.horizontal, AppSpacing.lg)

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let items = vm.achievements(for: category)
                    if !items.isEmpty {
                        categorySection(category: category, achievements: items)
                    }
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(Text("achievements.title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(
                achievement: achievement,
                isUnlocked: vm.isUnlocked(achievement),
                stats: vm.stats
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .accessibilityIdentifier("screen.achievements")
    }

    // MARK: — Progress Header

    private var progressHeader: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("achievements.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(verbatim: "\(vm.unlockedCount) / \(vm.totalCount)")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()

            ProgressPill(
                label: "\(Int(vm.overallProgress * 100))%",
                progress: vm.overallProgress
            )
        }
    }

    // MARK: — Category Section

    private func categorySection(category: AchievementCategory, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(category.displayNameKey)
                .padding(.horizontal, AppSpacing.lg)

            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(achievements) { achievement in
                    AchievementCell(
                        achievement: achievement,
                        isUnlocked: vm.isUnlocked(achievement),
                        stats: vm.stats
                    )
                    .onTapGesture { selectedAchievement = achievement }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

// MARK: — AchievementCell

private struct AchievementCell: View {

    let achievement: Achievement
    let isUnlocked: Bool
    var stats: AchievementStats?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Image(systemName: achievement.sfSymbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isUnlocked ? AppColors.primary : AppColors.outline)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .offset(x: 12, y: 12)
                }
            }
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(isUnlocked ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
            )

            Text(achievement.displayNameKey)
                .font(AppTypography.labelSmall)
                .tracking(0.2)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 4) {
                ForEach(Currency.allCases) { currency in
                    if let amount = achievement.reward[currency], amount > 0 {
                        HStack(spacing: 2) {
                            CurrencyIcon(currency: currency, size: 12)
                            Text(verbatim: "+\(amount)")
                                .font(AppTypography.numericSmall)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        }
                    }
                }
            }

            // Progress toward the goal — only on locked cells with a real target.
            if !isUnlocked, let stats {
                let p = AchievementRules.progress(achievement, stats: stats)
                if p.target > 1 {
                    VStack(spacing: 2) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppColors.surfaceContainerHigh)
                                Capsule().fill(AppColors.primary)
                                    .frame(width: geo.size.width * CGFloat(p.current) / CGFloat(p.target))
                            }
                        }
                        .frame(height: 4)
                        Text(verbatim: "\(p.current)/\(p.target)")
                            .font(AppTypography.numericSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .padding(.top, 2)
                }
            }

            // Completed badge — green "sun" with a white check.
            if isUnlocked {
                SunCheckBadge(size: 30)
                    .padding(.top, 2)
            }

            // Push content to the top so cards in the same row stay equal height
            // (locked cards add a progress bar; this keeps the pair aligned).
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .cardSurface()
        .opacity(isUnlocked ? 1.0 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(achievement.displayNameKey))
        .accessibilityHint(Text(isUnlocked ? "achievement.unlocked.banner.title" : "achievement.locked.label"))
    }
}

// MARK: — AchievementDetailSheet

private struct AchievementDetailSheet: View {

    let achievement: Achievement
    let isUnlocked: Bool
    let stats: AchievementStats

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: achievement.sfSymbol)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(isUnlocked ? AppColors.primary : AppColors.outline)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(isUnlocked ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                )
                .padding(.top, AppSpacing.lg)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.sm) {
                Text(achievement.displayNameKey)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                    .multilineTextAlignment(.center)

                Text(achievement.descriptionKey)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            HStack(spacing: AppSpacing.md) {
                ForEach(Currency.allCases) { currency in
                    if let amount = achievement.reward[currency], amount > 0 {
                        HStack(spacing: AppSpacing.xs) {
                            CurrencyIcon(currency: currency, size: 20)
                            Text(verbatim: "+\(amount)")
                                .font(AppTypography.numericLabel)
                                .foregroundStyle(AppColors.onSurface)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .cardSurface()
                    }
                }
            }

            if isUnlocked {
                ProgressPill(label: NSLocalizedString("achievement.unlocked.banner.title", comment: ""), progress: 1.0)
            } else {
                ProgressPill(label: NSLocalizedString("achievement.locked.label", comment: ""), progress: 0.0)
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .environment(AppRouter())
}
