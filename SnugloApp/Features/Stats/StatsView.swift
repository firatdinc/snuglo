import SwiftUI

// MARK: — StatsView (H-1: Localized)
// Ref: Designs/html/09-stats.html
// H-2: VoiceOver — KPI cards combined elements, pack donuts labelled.

// I: Replaces anonymous 4-member tuple — large_tuple lint fix.
// H-1: rawKey drives Text(pack.titleKey) for localized display.
private struct PackStat {
    let id: String
    let rawKey: String    // e.g. "pack.cozyBeginnings"
    let color: Color
    let icon: String
    var titleKey: LocalizedStringKey { LocalizedStringKey(rawKey) }
}

struct StatsView: View {

    @State private var store: ProgressStore = ProgressStore.shared

    private let packs: [PackStat] = [
        PackStat(id: "cozy-beginnings", rawKey: "pack.cozyBeginnings", color: AppColors.blockLavender, icon: "leaf.fill"),
        PackStat(id: "spice-route", rawKey: "pack.spiceRoute", color: AppColors.blockPeach, icon: "cup.and.saucer.fill"),
        PackStat(id: "mambo-nights", rawKey: "pack.mamboNights", color: AppColors.blockBlush, icon: "moon.stars.fill"),
        PackStat(id: "woodland-retreat", rawKey: "pack.woodlandRetreat", color: AppColors.blockSage, icon: "tree.fill")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                headerSection
                kpiGridSection
                packProgressSection
                chartSection
                donutSection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("stats.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.stats")
    }

    // MARK: — Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("stats.header")
                .font(AppTypography.headlineLarge)
                .tracking(-0.6)
                .foregroundStyle(AppColors.onSurface)
            Text(streakSubtitle)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }

    private var streakSubtitle: String {
        if store.currentStreak > 0 {
            return String(format: NSLocalizedString("stats.streakActive", comment: ""), store.currentStreak)
        }
        return NSLocalizedString("stats.streakEmpty", comment: "")
    }

    // MARK: — KPI Grid (H-2: each card combined + labelled)

    private var kpiGridSection: some View {
        let kpiCols = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)
        return LazyVGrid(columns: kpiCols, spacing: AppSpacing.sm) {
            kpiCard(
                value: levelsCompletedLabel,
                labelKey: "stats.levelsCompleted",
                icon: "checkmark.circle.fill",
                a11yLabel: "Levels completed: \(store.totalLevelsCompleted()) of 240",
                a11yId: "stats.total_completed"  // Faz I-2: UITest identifier
            )
            kpiCard(
                value: store.currentStreak > 0 ? "\(store.currentStreak)d" : "—",
                labelKey: "stats.streak",
                icon: "flame.fill",
                a11yLabel: store.currentStreak > 0
                    ? "Current streak: \(store.currentStreak) days"
                    : "No active streak"
            )
            kpiCard(
                value: store.averageTimeFormatted,
                labelKey: "stats.avgTime",
                icon: "clock.fill",
                a11yLabel: "Average solve time: \(store.averageTimeFormatted)"
            )
            kpiCard(
                value: "\(store.dailyResults.filter(\.solved).count)",
                labelKey: "stats.dailySolved",
                icon: "calendar.badge.checkmark",
                a11yLabel: "Daily puzzles solved: \(store.dailyResults.filter(\.solved).count)"
            )
        }
    }

    private var levelsCompletedLabel: String {
        "\(store.totalLevelsCompleted())/240"
    }

    private func kpiCard(value: String, labelKey: LocalizedStringKey, icon: String, a11yLabel: String, a11yId: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary)
                .accessibilityHidden(true)

            Text(value)
                .font(AppTypography.numericLarge)
                .foregroundStyle(AppColors.onSurface)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(labelKey)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
        // H-2: combine entire card into one VoiceOver element
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
        // Faz I-2: optional UITest identifier
        .accessibilityIdentifier(a11yId ?? "")
    }

    // MARK: — Pack Progress Donuts

    private var packProgressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("stats.packProgress")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            HStack(spacing: AppSpacing.md) {
                ForEach(packs, id: \.id) { pack in
                    packDonut(pack: pack)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
    }

    private func packDonut(pack: PackStat) -> some View {
        let completed = store.packCompletionCount(pack.id)
        let fraction  = CGFloat(completed) / 60.0
        return VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle()
                    .stroke(AppColors.surfaceContainerHigh, lineWidth: 7)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: min(fraction, 1))
                    .stroke(
                        pack.color,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.easeOut(duration: 0.6), value: fraction)

                Image(systemName: pack.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(fraction > 0 ? pack.color : AppColors.onSurfaceVariant.opacity(0.4))
            }

            Text(pack.titleKey)               // H-1 BLOCKER 1: localized pack name
                .font(AppTypography.labelSmall)
                .tracking(0.3)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(completed)/60")
                .font(AppTypography.numericSmall)
                .foregroundStyle(fraction > 0 ? AppColors.onSurface : AppColors.onSurfaceVariant.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        // H-2: VoiceOver donut label
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(NSLocalizedString(pack.rawKey, comment: "")) pack: \(completed) of 60 levels completed")
    }

    // MARK: — 7-day Bar Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("stats.last7Days")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            let days = store.recentDailyResults(days: 7)

            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: AppSpacing.xs) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barColor(solved: day.solved, isToday: day.isToday))
                            .frame(height: barHeight(solved: day.solved))
                            .frame(maxWidth: .infinity)
                            .animation(.easeOut(duration: 0.4), value: day.solved)

                        Text(day.label)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(day.isToday ? AppColors.primary : AppColors.onSurfaceVariant)
                    }
                    // H-2: each bar reads as "Mon: solved" / "Tue: missed"
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.label): \(day.solved ? "solved" : "missed")\(day.isToday ? ", today" : "")")
                }
            }
            .frame(height: 100)

            HStack(spacing: AppSpacing.md) {
                legendDot(color: AppColors.primary, labelKey: "stats.chartSolved")
                legendDot(color: AppColors.blockBlush.opacity(0.4), labelKey: "stats.chartMissed")
            }
            .accessibilityHidden(true) // legend is decorative; bars already labelled
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
    }

    private func barColor(solved: Bool, isToday: Bool) -> Color {
        if solved { return isToday ? AppColors.primary : AppColors.primaryContainer }
        return AppColors.blockBlush.opacity(isToday ? 0.35 : 0.2)
    }

    private func barHeight(solved: Bool) -> CGFloat {
        solved ? 80 : 12
    }

    private func legendDot(color: Color, labelKey: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(labelKey)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }

    // MARK: — Hint Usage Donut

    private var donutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("stats.hintUsage")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                Text(verbatim: "Coming in Faz G")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
            }

            HStack(spacing: AppSpacing.xl) {
                ZStack {
                    Circle()
                        .stroke(AppColors.surfaceContainerHigh, lineWidth: 16)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: 0.55)
                        .stroke(AppColors.primary,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0.55, to: 0.85)
                        .stroke(AppColors.primaryContainer,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)

                    VStack(spacing: 0) {
                        Text("—")
                            .font(AppTypography.numericLabel)
                            .foregroundStyle(AppColors.onSurface)
                        Text("per game")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }
                .accessibilityHidden(true) // static placeholder; real data in Faz G

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    legendRow(color: AppColors.surfaceContainerHigh, labelKey: "stats.noHints", value: "—")
                    legendRow(color: AppColors.primaryContainer, labelKey: "stats.hints1to2", value: "—")
                    legendRow(color: AppColors.primary, labelKey: "stats.hints3plus", value: "—")
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
    }

    private func legendRow(color: Color, labelKey: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(labelKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
            Spacer()
            Text(value)
                .font(AppTypography.numericSmall)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }
}

#Preview {
    NavigationStack { StatsView() }
        .environment(AppRouter())
}
