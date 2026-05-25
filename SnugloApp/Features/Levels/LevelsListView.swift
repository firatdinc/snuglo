import SwiftUI

// MARK: — LevelsListView
// Ref: Designs/html/04-levels-list.html
// LEVELS tab — 4 pack cards from MockData, locked ones grayscale.

struct LevelsListView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // — Header —
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
                    ForEach(MockData.allPacks) { pack in
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

    private func packCard(_ pack: Pack) -> some View {
        Button {
            guard !pack.isLocked else { return }
            router.push(.packDetail(packName: pack.title))
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.sm) {
                            Text(pack.title)
                                .font(AppTypography.headlineSmall)
                                .foregroundStyle(AppColors.onSurface)
                            if pack.isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                            }
                        }

                        Label(pack.subtitle, systemImage: "square.grid.2x2")
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
                            .fill(pack.accentColor)
                            .frame(width: 48, height: 48)
                        Image(systemName: pack.iconName)
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.primary)
                    }
                    .shadowL1()
                    .opacity(pack.isLocked ? 0.4 : 1.0)
                    .grayscale(pack.isLocked ? 0.7 : 0)
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
                            Text("\(pack.completedCount)")
                                .font(AppTypography.numericLabel)
                                .foregroundStyle(pack.isLocked ? AppColors.onSurfaceVariant : AppColors.primary)
                            + Text("/\(pack.levelCount)")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        )
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppColors.surfaceContainer)
                            let frac: CGFloat = pack.levelCount > 0
                                ? CGFloat(pack.completedCount) / CGFloat(pack.levelCount)
                                : 0
                            Capsule()
                                .fill(pack.isLocked ? AppColors.outlineVariant : AppColors.primary)
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
                    .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            }
            .shadowL1()
            .grayscale(pack.isLocked ? 0.4 : 0)
            .opacity(pack.isLocked ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .disabled(pack.isLocked)
    }
}

#Preview {
    NavigationStack {
        LevelsListView()
    }
    .environment(AppRouter())
}
