import SwiftUI

// MARK: — StatsView (Screen 09)
// Design reference: Designs/html/09-stats.html
//
// STATS tab. 2×2 KPI cards + weekly bar chart placeholder + donut placeholder.
// Charts will be real in Faz E — use RoundedRectangle placeholders now.

struct StatsView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                scrollContent
            }

            BottomTabBar()
        }
        .navigationBarHidden(true)
        .onAppear { router.selectedTab = .stats }
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            Button {
                router.push(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Snuglo")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)

            Spacer()

            // Balance spacer
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
    }

    // MARK: — Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Your Stats")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)
                }

                // 2×2 KPI grid
                kpiGrid

                // Weekly bar chart section
                chartSection(title: "Solves Per Day", subtitle: "This week") {
                    weeklyBarChart
                }

                // Hint usage donut section
                chartSection(title: "Hint Usage", subtitle: "1.2 per game") {
                    hintDonutPlaceholder
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: — KPI grid

    private var kpiGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: AppSpacing.sm), GridItem(.flexible(), spacing: AppSpacing.sm)],
            spacing: AppSpacing.sm
        ) {
            kpiCard(
                label: "SOLVED",
                value: "\(MockData.statSolved)",
                symbol: "checkmark.seal.fill",
                color: AppColors.blockLavender
            )
            kpiCard(
                label: "TIME",
                value: "\(MockData.statTimeHours)h",
                symbol: "clock.fill",
                color: AppColors.blockSage
            )
            kpiCard(
                label: "FASTEST",
                value: MockData.statFastest,
                symbol: "bolt.fill",
                color: AppColors.blockPeach
            )
            kpiCard(
                label: "STREAK",
                value: "\(MockData.statStreak)d",
                symbol: "flame.fill",
                color: AppColors.blockBlush
            )
        }
    }

    private func kpiCard(label: String, value: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.primary)
            }

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.onSurface)
                .tracking(-0.5)

            // Label
            Text(label)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadowL1()
    }

    // MARK: — Chart section wrapper

    private func chartSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)

                Text(subtitle)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            content()
        }
    }

    // MARK: — Weekly bar chart (Faz E: real Chart; Faz C: bar view)

    private var weeklyBarChart: some View {
        VStack(spacing: AppSpacing.md) {
            // Bars
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(MockData.weeklyBar, id: \.day) { item in
                    VStack(spacing: AppSpacing.xs) {
                        let maxCount = MockData.weeklyBar.map(\.count).max() ?? 1
                        let fraction = maxCount > 0 ? Double(item.count) / Double(maxCount) : 0

                        Spacer()

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(item.isToday ? AppColors.primary : AppColors.primaryContainer.opacity(0.5))
                            .frame(height: max(4, CGFloat(fraction) * 90))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: fraction)

                        Text(item.day)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(item.isToday ? AppColors.primary : AppColors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
            .padding(AppSpacing.md)
            .background(AppColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL1()

            Text("Full chart · Faz E")
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.outlineVariant)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: — Hint donut placeholder

    private var hintDonutPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                AppColors.surfaceContainerLow
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    .shadowL1()

                HStack(spacing: AppSpacing.xl) {
                    // Donut outline placeholder
                    ZStack {
                        Circle()
                            .stroke(AppColors.surfaceContainerHighest, lineWidth: 18)
                            .frame(width: 90, height: 90)

                        Circle()
                            .trim(from: 0, to: 0.55)
                            .stroke(AppColors.primaryContainer, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))

                        Circle()
                            .trim(from: 0.55, to: 0.8)
                            .stroke(AppColors.blockSage, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        legendItem(color: AppColors.primaryContainer, label: "No hints")
                        legendItem(color: AppColors.blockSage, label: "1–2 hints")
                        legendItem(color: AppColors.surfaceContainerHighest, label: "3+ hints")
                    }

                    Spacer()
                }
                .padding(AppSpacing.md)
            }
            .frame(height: 130)

            Text("Full donut chart · Faz E")
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.outlineVariant)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        StatsView()
    }
    .environment(AppRouter())
}
