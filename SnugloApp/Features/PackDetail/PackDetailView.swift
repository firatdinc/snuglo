import SwiftUI

// MARK: — PackDetailView (Faz 3a: Vibrant Play restyle)
// Design reference: Designs/VibrantPlay/level-map.png
// Hero: Image("scene-island") full-width with gradient scrim + cardSurface info card.
// Level nodes: circles — completed: primary fill + white text; available: white + primary border; locked: surfaceContainerHigh.
// H-2: VoiceOver — each level tile has a full label (number, stars, status).

struct PackDetailView: View {

    @Environment(AppRouter.self) private var router
    let packName: String

    private var pack: Pack? {
        MockData.allPacks.first { $0.title == packName || $0.id == packName }
    }

    private var levels: [LevelItem] {
        guard let currentPack = pack else { return [] }
        return PackProvider.levelItems(in: currentPack.id)
    }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 4)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner
                    .padding(.bottom, AppSpacing.xl)

                LazyVGrid(columns: gridColumns, spacing: AppSpacing.md) {
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
        .accessibilityIdentifier("screen.packDetail")
    }

    // MARK: — Hero banner

    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            Image("scene-island")
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, AppColors.background.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .accessibilityHidden(true)

            if let packData = pack {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("BEGINNER", systemImage: "sparkles")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primaryContainer.opacity(0.4), in: Capsule())
                        .accessibilityHidden(true)

                    Text(packData.title)
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)

                    Text(packData.subtitle)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)

                    HStack(spacing: AppSpacing.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppColors.surfaceContainerHigh)
                                let frac = CGFloat(packData.completedCount) / CGFloat(packData.levelCount)
                                Capsule()
                                    .fill(AppColors.primary)
                                    .frame(width: geo.size.width * frac)
                            }
                        }
                        .frame(height: 10)

                        Text("\(packData.completedCount)/\(packData.levelCount)")
                            .font(AppTypography.numericSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(packData.completedCount) of \(packData.levelCount) levels completed")
                }
                .padding(AppSpacing.md)
                .cardSurface()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
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
                Circle()
                    .fill(tileBackground(level))
                    .overlay(
                        Circle()
                            .stroke(tileBorder(level), lineWidth: level.isCompleted ? 0 : 1.5)
                    )
                    .shadowL1()

                if level.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                        .accessibilityHidden(true)
                } else if level.isCompleted {
                    VStack(spacing: 2) {
                        Text("\(level.index)")
                            .font(AppTypography.numericSmall)
                            .foregroundStyle(.white)
                        HStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { starIdx in
                                Image(systemName: starIdx < level.stars ? "star.fill" : "star")
                                    .font(.system(size: 7))
                                    .foregroundStyle(AppColors.tertiary)
                            }
                        }
                    }
                    .accessibilityHidden(true)
                } else {
                    Text("\(level.index)")
                        .font(AppTypography.numericLabel)
                        .foregroundStyle(AppColors.onSurface)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .disabled(level.isLocked)
        .accessibilityLabel(levelTileA11yLabel(level))
        .accessibilityHint(level.isLocked ? "" : "Tap to play this level")
        .accessibilityIdentifier("packdetail.level_item.\(level.index - 1)")
    }

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
        if level.isCompleted { return AppColors.primary }
        if level.isLocked { return AppColors.surfaceContainerHigh }
        return AppColors.surfaceContainerLowest
    }

    private func tileBorder(_ level: LevelItem) -> Color {
        if level.isCompleted { return .clear }
        if level.isLocked { return AppColors.outlineVariant.opacity(0.3) }
        return AppColors.primary.opacity(0.5)
    }
}

#Preview {
    NavigationStack {
        PackDetailView(packName: "Cozy Beginnings")
    }
    .environment(AppRouter())
}
