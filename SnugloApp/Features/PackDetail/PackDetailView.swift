import SwiftUI

// MARK: — PackDetailView (Screen 05)
// Design reference: Designs/html/05-pack-detail.html
//
// • Hero banner with pack name, subtitle badge, progress bar
// • 3-column grid of level tiles: completed (number + stars), current (highlighted), locked (🔒)
// • Tapping a non-locked tile → .gamePlay(levelId:)

struct PackDetailView: View {

    let packId: String

    @Environment(AppRouter.self) private var router

    private var pack: Pack? { MockData.allPacks.first { $0.id == packId } }
    private var levels: [LevelItem] { MockData.levels(for: packId) }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 3)

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroBanner
                    levelGrid
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Custom back button overlay
            VStack {
                HStack {
                    Button {
                        router.pop()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.background.opacity(0.85))
                            .clipShape(Circle())
                            .shadowL1()
                    }
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, 56)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: — Hero banner

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Rectangle()
                .fill(pack?.accentColor.opacity(0.3) ?? AppColors.surfaceContainer)
                .frame(height: 220)

            // Decorative grid pattern
            GridPatternView()
                .opacity(0.15)
                .frame(height: 220)
                .clipped()

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let pack {
                    Text(pack.subtitle)
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.secondary)

                    Text(pack.title)
                        .font(AppTypography.headlineMedium)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.4)

                    // Progress
                    HStack(spacing: AppSpacing.md) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 99, style: .continuous)
                                    .fill(AppColors.surfaceContainerHigh)
                                    .frame(height: 12)

                                RoundedRectangle(cornerRadius: 99, style: .continuous)
                                    .fill(AppColors.primary)
                                    .frame(width: geo.size.width * pack.progressFraction, height: 12)
                            }
                        }
                        .frame(height: 12)

                        Text("\(pack.completedCount) / \(pack.levelCount)")
                            .font(AppTypography.numericLabel)
                            .foregroundStyle(AppColors.primary)
                            .fixedSize()
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .clipShape(
            .rect(
                topLeadingRadius: 0, bottomLeadingRadius: AppRadius.card,
                bottomTrailingRadius: AppRadius.card, topTrailingRadius: 0
            )
        )
    }

    // MARK: — Level grid

    private var levelGrid: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(levels) { level in
                levelTile(level)
            }
        }
    }

    @ViewBuilder
    private func levelTile(_ level: LevelItem) -> some View {
        if level.isLocked {
            lockedTile(level)
        } else {
            Button {
                router.push(.gamePlay(levelId: level.id))
            } label: {
                if level.isCompleted {
                    completedTile(level)
                } else {
                    currentTile(level)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func completedTile(_ level: LevelItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text("\(level.number)")
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .foregroundStyle(AppColors.primary)

            // Stars
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { star in
                    Image(systemName: star <= level.stars ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.blockCream)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        .shadowL1()
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }

    private func currentTile(_ level: LevelItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text("\(level.number)")
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .foregroundStyle(AppColors.primary)

            // Empty star row (placeholder)
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { _ in
                    Image(systemName: "star")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.outlineVariant)
                }
            }
            .opacity(0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        .shadow(color: AppColors.primaryContainer.opacity(0.8), radius: 8, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                .stroke(AppColors.primaryContainer, lineWidth: 2)
        )
    }

    private func lockedTile(_ level: LevelItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.outline)

            Text("\(level.number)")
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.outline)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(AppColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        .shadow(color: AppColors.shadowAmbient.opacity(0.02), radius: 2, x: 0, y: 1)
        .opacity(0.7)
    }
}

// MARK: — Decorative grid pattern

private struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            var x: CGFloat = 0
            while x < size.width {
                context.stroke(
                    Path { p in p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height)) },
                    with: .color(AppColors.onSurface),
                    lineWidth: 0.5
                )
                x += spacing
            }
            var y: CGFloat = 0
            while y < size.height {
                context.stroke(
                    Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y)) },
                    with: .color(AppColors.onSurface),
                    lineWidth: 0.5
                )
                y += spacing
            }
        }
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        PackDetailView(packId: "cozy-beginnings")
    }
    .environment(AppRouter())
}
