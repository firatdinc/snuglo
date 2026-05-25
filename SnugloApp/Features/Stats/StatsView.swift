import SwiftUI

// MARK: — StatsView
// Ref: Designs/html/09-stats.html
// STATS tab: 2×2 KPI grid, weekly bar chart placeholder, hint donut placeholder.

struct StatsView: View {

    // Mock data — replace with persistence in Faz E
    private let kpis: [(value: String, label: String, icon: String)] = [
        ("142",  "SOLVED",  "checkmark.circle.fill"),
        ("48h",  "TIME",    "clock.fill"),
        ("1:12", "FASTEST", "bolt.fill"),
        ("14d",  "STREAK",  "flame.fill")
    ]

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    private let barHeights: [CGFloat] = [0.5, 0.7, 0.4, 0.9, 0.6, 0.3, 1.0]
    private let todayIndex = 6  // Sunday (last bar)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // — Header —
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Your Stats")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)
                    Text("Keep the streak going 🔥")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                // — 2×2 KPI grid —
                let kpiCols = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 2)
                LazyVGrid(columns: kpiCols, spacing: AppSpacing.sm) {
                    ForEach(Array(kpis.enumerated()), id: \.offset) { _, kpi in
                        kpiCard(kpi)
                    }
                }

                // — Solves per day chart —
                chartCard

                // — Hint usage donut —
                donutCard
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — KPI card

    private func kpiCard(_ kpi: (value: String, label: String, icon: String)) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: kpi.icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary)

            Text(kpi.value)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppColors.onSurface)

            Text(kpi.label)
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

    // MARK: — Weekly bar chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Solves per day")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(Array(zip(weekdays, barHeights).enumerated()), id: \.offset) { i, pair in
                    VStack(spacing: AppSpacing.xs) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(i == todayIndex ? AppColors.primary : AppColors.blockBlush.opacity(0.7))
                            .frame(height: 80 * pair.1)
                            .frame(maxWidth: .infinity)

                        Text(pair.0)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(i == todayIndex ? AppColors.primary : AppColors.onSurfaceVariant)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
        )
        .shadowL1()
    }

    // MARK: — Hint usage donut

    private var donutCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Hint usage")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            HStack(spacing: AppSpacing.xl) {
                // Donut placeholder
                ZStack {
                    Circle()
                        .stroke(AppColors.surfaceContainerHigh, lineWidth: 16)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: 0.55)
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0.55, to: 0.85)
                        .stroke(AppColors.primaryContainer, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)

                    VStack(spacing: 0) {
                        Text("1.2")
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppColors.onSurface)
                        Text("per game")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    legendRow(color: AppColors.surfaceContainerHigh, label: "No hints", value: "55%")
                    legendRow(color: AppColors.primaryContainer,    label: "1–2 hints",  value: "30%")
                    legendRow(color: AppColors.primary,             label: "3+ hints",   value: "15%")
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
