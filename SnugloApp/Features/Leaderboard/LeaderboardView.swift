import SwiftUI

// MARK: — LeaderboardView

struct LeaderboardView: View {

    @State private var viewModel = LeaderboardViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var bvm = viewModel

        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("leaderboard.title")
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(AppColors.onSurface)
                    .tracking(-0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.md)

                Picker("", selection: $bvm.selectedBoard) {
                    Text("leaderboard.board.totalLevels").tag(LeaderboardID.totalLevels)
                    Text("leaderboard.board.fastestSolve").tag(LeaderboardID.fastestSolve)
                    Text("leaderboard.board.bestStreak").tag(LeaderboardID.bestStreak)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)
                .accessibilityIdentifier("leaderboard.board.picker")

                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        stateContent
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
                .refreshable { await viewModel.load() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.leaderboard")
        .task { await viewModel.load() }
        .onChange(of: viewModel.selectedBoard) {
            Task { await viewModel.load() }
        }
    }

    // MARK: — State Renders

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.xl)

        case .loaded(let entries):
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, boardID: viewModel.selectedBoard)
                    .accessibilityIdentifier("leaderboard.row.\(index)")
            }

        case .empty:
            emptyCard

        case .notSignedIn:
            AnnouncementBanner(
                titleKey: "leaderboard.notSignedIn.title",
                messageKey: "leaderboard.notSignedIn.body",
                ctaKey: "leaderboard.notSignedIn.cta",
                onCTA: {
                    if let url = URL(string: "app-settings:") { openURL(url) }
                }
            )
            .accessibilityIdentifier("button.leaderboard.signin")

            ForEach(Array(viewModel.fallbackEntries.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, boardID: viewModel.selectedBoard)
                    .accessibilityIdentifier("leaderboard.row.\(index)")
            }

        case .error:
            AnnouncementBanner(
                titleKey: "leaderboard.error.title",
                messageKey: "leaderboard.error.body"
            )

            Button {
                Task { await viewModel.load() }
            } label: {
                Text("common.retry")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.primary)
            }
            .accessibilityIdentifier("button.leaderboard.refresh")
        }
    }

    private var emptyCard: some View {
        VStack(spacing: AppSpacing.md) {
            Text("leaderboard.empty.title")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
            Text("leaderboard.empty.body")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }
}

// MARK: — LeaderboardRow

private struct LeaderboardRow: View {
    let entry: GameCenterEntry
    let boardID: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            rankBadge
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.onSurface)
                if entry.isSimulated {
                    Text("leaderboard.sample")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .tracking(0.6)
                }
            }

            Spacer()

            Text(formattedScore)
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
                .monospacedDigit()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                .fill(entry.isLocalPlayer
                    ? AppColors.primaryContainer.opacity(0.35)
                    : AppColors.surfaceContainerLowest)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous)
                .stroke(
                    entry.isLocalPlayer ? AppColors.primary : AppColors.outlineVariant.opacity(0.3),
                    lineWidth: entry.isLocalPlayer ? 1.5 : 0.5
                )
        )
    }

    @ViewBuilder
    private var rankBadge: some View {
        let rankLabel = String(format: NSLocalizedString("leaderboard.row.rank", comment: ""), entry.rank)
        switch entry.rank {
        case 1:
            Image(systemName: "trophy.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.tertiary)
                .accessibilityLabel(Text(verbatim: rankLabel))
        case 2:
            Image(systemName: "medal.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.outline)
                .accessibilityLabel(Text(verbatim: rankLabel))
        case 3:
            Image(systemName: "medal.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.secondary)
                .accessibilityLabel(Text(verbatim: rankLabel))
        default:
            Text("\(entry.rank)")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .frame(maxWidth: .infinity)
        }
    }

    private var formattedScore: String {
        if boardID == LeaderboardID.fastestSolve {
            guard entry.score > 0 else { return "--:--" }
            let totalSec = entry.score / 1000
            return String(format: "%d:%02d", totalSec / 60, totalSec % 60)
        }
        return "\(entry.score)"
    }
}

// MARK: — Preview

#Preview {
    LeaderboardView()
}
