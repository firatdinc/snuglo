import SwiftUI

// MARK: — PackDetailView
// Ref: Designs/html/05-pack-detail.html
// 30-level grid for a given pack. Tap active level → game.

struct PackDetailView: View {

    let packName: String

    @Environment(AppRouter.self) private var router

    // MARK: — Level state helpers

    private enum LevelState {
        case completed(stars: Int)  // 1-3
        case active
        case locked
    }

    private func state(for index: Int) -> LevelState {
        if index < 18 { return .completed(stars: index % 3 == 0 ? 2 : 3) }
        if index == 18 { return .active }
        return .locked
    }

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Banner
                banner

                // Level grid
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("LEVELS")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .padding(.horizontal, AppSpacing.lg)

                    LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                        ForEach(0..<30, id: \.self) { idx in
                            levelTile(idx)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                Color.clear.frame(height: AppSpacing.xl)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(packName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface.opacity(0.85), for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }

    // MARK: — Banner

    private var banner: some View {
        ZStack(alignment: .bottomLeading) {
            AppColors.secondaryContainer.opacity(0.25)
                .frame(maxWidth: .infinity)
                .frame(height: 240)

            LinearGradient(
                colors: [.clear, AppColors.background.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Progress bar
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text("PROGRESS")
                            .font(AppTypography.labelSmall)
                            .tracking(0.6)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                        Spacer()
                        (
                            Text("18")
                                .font(AppTypography.numericLabel)
                                .foregroundStyle(AppColors.primary)
                            + Text(" / 30")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        )
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppColors.surfaceContainerHigh)
                            Capsule()
                                .fill(AppColors.primary)
                                .frame(width: geo.size.width * (18.0 / 30.0))
                        }
                    }
                    .frame(height: 10)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surfaceContainerLowest.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .shadowL1()
            }
            .padding(AppSpacing.md)
        }
        .clipShape(
            .rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: AppRadius.card,
                bottomTrailingRadius: AppRadius.card,
                topTrailingRadius: 0
            )
        )
    }

    // MARK: — Level tile

    @ViewBuilder
    private func levelTile(_ index: Int) -> some View {
        let lvl = index + 1
        let s = state(for: index)

        Button {
            if case .locked = s { return }
            router.push(.game(levelID: "\(packName)-\(lvl)"))
        } label: {
            ZStack {
                tileBackground(s)

                VStack(spacing: AppSpacing.xs) {
                    Text("\(lvl)")
                        .font(AppTypography.numericLabel)
                        .foregroundStyle(tileForeground(s))

                    if case .completed(let stars) = s {
                        starRow(stars)
                    } else if case .locked = s {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
        }
        .buttonStyle(.plain)
        .disabled({ if case .locked = s { return true }; return false }())
    }

    private func tileBackground(_ s: LevelState) -> some View {
        Group {
            switch s {
            case .completed:
                RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                    .fill(AppColors.primaryContainer.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                            .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
                    }
            case .active:
                RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                    .fill(AppColors.primary)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.white.opacity(0.5))
                            .frame(height: 1)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous))
                    }
            case .locked:
                RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                    .fill(AppColors.surfaceContainer)
            }
        }
        .shadowL1()
    }

    private func tileForeground(_ s: LevelState) -> Color {
        switch s {
        case .completed: return AppColors.primary
        case .active:    return AppColors.onPrimary
        case .locked:    return AppColors.onSurfaceVariant.opacity(0.4)
        }
    }

    private func starRow(_ count: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < count ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(i < count ? AppColors.tertiary : AppColors.surfaceContainerHigh)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PackDetailView(packName: "Cozy Beginnings")
    }
    .environment(AppRouter())
}
