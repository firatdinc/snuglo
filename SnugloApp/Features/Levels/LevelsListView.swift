import SwiftUI

// MARK: — LevelsListView
// Ref: Designs/html/04-levels-list.html
// LEVELS tab content — pack cards with name, grid size badge, icon, progress.

private struct LevelPack: Identifiable {
    let id:       String
    let name:     String
    let gridSize: String
    let icon:     String
    let solved:   Int
    let total:    Int
    let accent:   Color
}

private let mockPacks: [LevelPack] = [
    .init(id: "cozy",   name: "Cozy Beginnings",  gridSize: "5×5",
          icon: "leaf.fill",           solved: 18, total: 30, accent: AppColors.primaryContainer),
    .init(id: "spice",  name: "Spice Route",       gridSize: "6×6",
          icon: "cup.and.saucer.fill", solved: 4,  total: 30, accent: AppColors.secondaryContainer),
    .init(id: "nordic", name: "Nordic Hearth",      gridSize: "7×7",
          icon: "snowflake",           solved: 0,  total: 30, accent: AppColors.tertiaryContainer)
]

struct LevelsListView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Levels")
                        .font(AppTypography.headlineLarge)
                        .tracking(-0.6)
                        .foregroundStyle(AppColors.onSurface)
                    Text("Pick a pack")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                VStack(spacing: AppSpacing.md) {
                    ForEach(mockPacks) { pack in
                        packCard(pack)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Snuglo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { router.push(.settings) } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.shop) } label: {
                    Image(systemName: "bag")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
        }
        .toolbarBackground(AppColors.surface.opacity(0.85), for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }

    // MARK: — Pack card

    private func packCard(_ pack: LevelPack) -> some View {
        Button {
            router.push(.packDetail(packName: pack.name))
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(pack.name)
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onSurface)

                        Label(pack.gridSize, systemImage: "square.grid.2x2")
                            .font(AppTypography.labelSmall)
                            .tracking(0.6)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(
                                AppColors.surfaceContainer,
                                in: RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous)
                            )
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                            .fill(pack.accent)
                            .frame(width: 48, height: 48)
                        Image(systemName: pack.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.primary)
                    }
                    .shadowL1()
                }

                // Progress
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text("PROGRESS")
                            .font(AppTypography.labelSmall)
                            .tracking(0.6)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                        Spacer()
                        (
                            Text("\(pack.solved)")
                                .font(AppTypography.numericLabel)
                                .foregroundStyle(AppColors.primary)
                            + Text("/\(pack.total)")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        )
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppColors.surfaceContainer)
                            let frac = pack.total > 0
                                ? CGFloat(pack.solved) / CGFloat(pack.total)
                                : 0
                            Capsule()
                                .fill(AppColors.primary)
                                .frame(width: geo.size.width * frac)
                        }
                    }
                    .frame(height: 12)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadowL1()
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        LevelsListView()
    }
    .environment(AppRouter())
}
