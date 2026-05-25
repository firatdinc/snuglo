import SwiftUI

// MARK: — PackDetailView
// Ref: Designs/html/05-pack-detail.html
// Hero banner with pack info + progress, then 3-column 60-tile level grid.
// Tapping an unlocked tile → router.push(.game(levelID:))

struct PackDetailView: View {

    @Environment(AppRouter.self) private var router
    let packName: String

    private var pack: Pack? {
        MockData.allPacks.first { $0.title == packName || $0.id == packName }
    }

    private var levels: [LevelItem] {
        guard let p = pack else { return [] }
        return MockData.levels(in: p.id)
    }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 3)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner
                    .padding(.bottom, AppSpacing.xl)

                LazyVGrid(columns: gridColumns, spacing: AppSpacing.sm) {
                    ForEach(levels) { level in
                        levelTile(level)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(packName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Hero banner

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    (pack?.accentColor ?? AppColors.primaryContainer).opacity(0.4),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let p = pack {
                    Label("BEGINNER", systemImage: "sparkles")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primaryContainer.opacity(0.4), in: Capsule())

                    Text(p.title)
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)

                    Text(p.subtitle)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)

                    // Progress bar
                    HStack(spacing: AppSpacing.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppColors.surfaceContainerHigh)
                                let frac = CGFloat(p.completedCount) / CGFloat(p.levelCount)
                                Capsule()
                                    .fill(AppColors.primary)
                                    .frame(width: geo.size.width * frac)
                            }
                        }
                        .frame(height: 10)

                        Text("\(p.completedCount)/\(p.levelCount)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }

    // MARK: — Level tile

    @ViewBuilder
    private func levelTile(_ level: LevelItem) -> some View {
        Button {
            guard !level.isLocked else { return }
            router.push(.game(levelID: level.id))
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                    .fill(tileBackground(level))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                            .stroke(tileBorder(level), lineWidth: level.isCompleted ? 0 : 1.5)
                    )

                if level.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                } else if level.isCompleted {
                    VStack(spacing: 2) {
                        Text("\(level.index)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppColors.primary)
                        HStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < level.stars ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundStyle(AppColors.tertiary)
                            }
                        }
                    }
                } else {
                    Text("\(level.index)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppColors.onSurface)
                }
            }
            .frame(height: 64)
        }
        .buttonStyle(.plain)
        .disabled(level.isLocked)
    }

    private func tileBackground(_ level: LevelItem) -> Color {
        if level.isCompleted { return AppColors.primaryContainer.opacity(0.3) }
        if level.isLocked { return AppColors.surfaceContainerLow }
        return AppColors.surfaceContainerLowest
    }

    private func tileBorder(_ level: LevelItem) -> Color {
        level.isLocked ? AppColors.outlineVariant.opacity(0.3) : AppColors.outline.opacity(0.25)
    }
}

#Preview {
    NavigationStack {
        PackDetailView(packName: "Cozy Beginnings")
    }
    .environment(AppRouter())
}
