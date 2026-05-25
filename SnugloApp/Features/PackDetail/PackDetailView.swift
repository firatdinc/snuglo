import SwiftUI

// MARK: — PackDetailView
// Ref: Designs/html/05-pack-detail.html
// H-2: VoiceOver — each level tile has a full label (number, stars, status).

struct PackDetailView: View {

    @Environment(AppRouter.self) private var router
    let packName: String

    private var pack: Pack? {
        MockData.allPacks.first { $0.title == packName || $0.id == packName }
    }

    private var levels: [LevelItem] {
        guard let p = pack else { return [] }
        return PackProvider.levelItems(in: p.id)
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
            LinearGradient(
                colors: [
                    (pack?.accentColor ?? AppColors.primaryContainer).opacity(0.4),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .accessibilityHidden(true) // Decorative gradient

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
                        .accessibilityHidden(true) // decorative badge

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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(p.completedCount) of \(p.levelCount) levels completed")
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
                        .accessibilityHidden(true)
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
                    .accessibilityHidden(true) // conveyed by button label
                } else {
                    Text("\(level.index)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppColors.onSurface)
                        .accessibilityHidden(true) // conveyed by button label
                }
            }
            .frame(height: 64)
        }
        .buttonStyle(.plain)
        .disabled(level.isLocked)
        // H-2: descriptive label per tile
        .accessibilityLabel(levelTileA11yLabel(level))
        .accessibilityHint(level.isLocked ? "" : "Tap to play this level")
    }

    /// H-2: "Level 12, 3 stars, completed" / "Level 5, in progress" / "Level 8, locked"
    private func levelTileA11yLabel(_ level: LevelItem) -> String {
        if level.isLocked {
            return "Level \(level.index), locked"
        } else if level.isCompleted {
            return "Level \(level.index), \(level.stars) of 3 stars, completed"
        } else {
            return "Level \(level.index)"
        }
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
