import SwiftUI

// MARK: — StatsView
// Ref: Designs/html/09-stats.html
// STATS tab: 2×2 KPI grid (real data), pack progress donuts (real data),
// 7-day bar chart (real data), hint donut (static — real data: Faz G).
//
// Faz E: All KPI + chart data sourced from ProgressStore.shared.

struct StatsView: View {

    @State private var store: ProgressStore = ProgressStore.shared

    // Pack definitions for donut section
    private let packs: [(id: String, title: String, color: Color, icon: String)] = [
        ("cozy-beginnings", "Cozy",    AppColors.blockLavender, "leaf.fill"),
        ("spice-route",     "Spice",   AppColors.blockPeach,    "cup.and.saucer.fill"),
        ("mambo-nights",    "Mambo",   AppColors.blockBlush,    "moon.stars.fill"),
        ("woodland-retreat","Woodland",AppColors.blockSage,     "tree.fill")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {

                // — Header —
                headerSection

                // — 2×2 KPI grid (real data) —
                kpiGridSection

                // — Pack progress donuts (real data) —
                packProgressSection

                // — 7-day bar chart (real data) —
                chartSection

                // — Hint usage donut (static; real data: Faz G) —
                donutSection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Your Stats")
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
            return "🔥 \(store.currentStreak)-day streak — keep it going!"
        }
        return "Play today's daily puzzle to start a streak 🧩"
    }

    // MARK: — KPI Grid

    private var kpiGridSection: some View {
        let kpiCols = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)
        return LazyVGrid(columns: kpiCols, spacing: AppSpacing.sm) {
            kpiCard(
                value: levelsCompletedLabel,
                label: "LEVELS",
                icon: "checkmark.circle.fill"
            )
            kpiCard(
                value: store.currentStreak > 0 ? "\(store.currentStreak)d" : "—",
                label: "STREAK",
                icon: "flame.fill"
            )
            kpiCard(
                value: store.averageTimeFormatted,
                label: "AVG TIME",
                icon: "clock.fill"
            )
            kpiCard(
                value: "\(store.dailyResults.filter(\.solved).count)",
                label: "DAILY SOLVED",
                icon: "calendar.badge.checkmark"
            )
        }
    }

    private var levelsCompletedLabel: String {
        "\(store.totalLevelsCompleted())/240"
    }

    private func kpiCard(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary)

            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppColors.onSurface)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
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
    }

    // MARK: — Pack Progress Donuts

    private var packProgressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Pack Progress")
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

    private func packDonut(pack: (id: String, title: String, color: Color, icon: String)) -> some View {
        let completed = store.packCompletionCount(pack.id)
        let fraction  = CGFloat(completed) / 60.0
        return VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Track
                Circle()
                    .stroke(AppColors.surfaceContainerHigh, lineWidth: 7)
                    .frame(width: 56, height: 56)

                // Fill
                Circle()
                    .trim(from: 0, to: min(fraction, 1))
                    .stroke(
                        pack.color,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.easeOut(duration: 0.6), value: fraction)

                // Icon
                Image(systemName: pack.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(fraction > 0 ? pack.color : AppColors.onSurfaceVariant.opacity(0.4))
            }

            Text(pack.title)
                .font(AppTypography.labelSmall)
                .tracking(0.3)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(completed)/60")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(fraction > 0 ? AppColors.onSurface : AppColors.onSurfaceVariant.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — 7-day Bar Chart (real daily data)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Solves per day")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            let days = store.recentDailyResults(days: 7)

            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: AppSpacing.xs) {
                        // Bar
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barColor(solved: day.solved, isToday: day.isToday))
                            .frame(height: barHeight(solved: day.solved))
                            .frame(maxWidth: .infinity)
                            .animation(.easeOut(duration: 0.4), value: day.solved)

                        // Day label
                        Text(day.label)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(day.isToday ? AppColors.primary : AppColors.onSurfaceVariant)
                    }
                }
            }
            .frame(height: 100)

            // Legend
            HStack(spacing: AppSpacing.md) {
                legendDot(color: AppColors.primary, label: "Solved")
                legendDot(color: AppColors.blockBlush.opacity(0.4), label: "Missed")
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

    private func barColor(solved: Bool, isToday: Bool) -> Color {
        if solved { return isToday ? AppColors.primary : AppColors.primaryContainer }
        return AppColors.blockBlush.opacity(isToday ? 0.35 : 0.2)
    }

    private func barHeight(solved: Bool) -> CGFloat {
        solved ? 80 : 12
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }

    // MARK: — Hint Usage Donut (static; real data: Faz G)

    private var donutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Hint usage")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                Text("Coming in Faz G")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
            }

            HStack(spacing: AppSpacing.xl) {
                // Donut
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
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppColors.onSurface)
                        Text("per game")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    legendRow(color: AppColors.surfaceContainerHigh, label: "No hints",  value: "—")
                    legendRow(color: AppColors.primaryContainer,     label: "1–2 hints", value: "—")
                    legendRow(color: AppColors.primary,              label: "3+ hints",  value: "—")
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

    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }
}

#Preview {
    NavigationStack { StatsView() }
        .environment(AppRouter())
}
