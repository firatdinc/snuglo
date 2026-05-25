import SwiftUI

// MARK: — LevelCompleteSheet
// Ref: Designs/html/08-level-complete.html
// Presented as a bottom sheet after solving a level.
// Stars: 1-3. Hint count + elapsed time shown.

struct LevelCompleteSheet: View {

    let elapsedSeconds: Int
    let stars:          Int  // 1-3
    let hintsUsed:      Int
    let onNextLevel: () -> Void
    let onReplay:    () -> Void
    let onHome:      () -> Void

    var body: some View {
        ZStack {
            // Dimmer behind sheet
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack {
                Spacer()
                sheetContent
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: — Sheet

    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(AppColors.outlineVariant.opacity(0.5))
                .frame(width: 48, height: 6)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)

            VStack(spacing: AppSpacing.xl) {
                // Check circle
                checkCircle

                // Headline
                Text("Level complete!")
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.onSurface)

                // Thumbnail grid (decorative)
                puzzleThumbnail

                // Stats row
                statsRow

                // Action buttons
                actionButtons
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .clipShape(
            .rect(
                topLeadingRadius: AppRadius.card,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: AppRadius.card
            )
        )
        .shadowL2()
    }

    // MARK: — Check circle

    private var checkCircle: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F5E6E0").opacity(0.8))
                .frame(width: 96 * 1.25, height: 96 * 1.25)
                .blur(radius: 16)
            Circle()
                .fill(Color(hex: "#F5E6E0"))
                .frame(width: 96 * 1.1, height: 96 * 1.1)
            Circle()
                .fill(AppColors.primaryContainer)
                .frame(width: 64, height: 64)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(height: 1)
                        .clipShape(Circle())
                }
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.onPrimaryContainer)
        }
    }

    // MARK: — Puzzle thumbnail

    private var puzzleThumbnail: some View {
        let tileColors: [Color] = [
            AppColors.primary.opacity(0.2),
            AppColors.tertiaryContainer.opacity(0.4),
            AppColors.secondaryContainer.opacity(0.6),
            AppColors.primaryContainer,
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            ForEach(tileColors.indices, id: \.self) { i in
                tileColors[i]
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .frame(height: 44)
            }
        }
        .padding(AppSpacing.sm)
        .frame(width: 96, height: 96)
        .background(Color(hex: "#F2EBE0"))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.block, style: .continuous))
        .shadowL1()
    }

    // MARK: — Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(label: "Time", content: AnyView(
                Text(formattedTime)
                    .font(AppTypography.numericLabel)
                    .foregroundStyle(AppColors.primary)
            ))
            Divider().frame(width: 1).opacity(0.3)
            statCell(label: "Stars", content: AnyView(
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundStyle(i < stars ? AppColors.tertiary : AppColors.surfaceContainerHigh)
                    }
                }
            ))
            Divider().frame(width: 1).opacity(0.3)
            statCell(label: "Hints", content: AnyView(
                Text("\(hintsUsed)")
                    .font(AppTypography.numericLabel)
                    .foregroundStyle(AppColors.secondary)
            ))
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadowL1()
    }

    private func statCell(label: String, content: AnyView) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label.uppercased())
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .foregroundStyle(AppColors.onSurfaceVariant)
            content
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Action buttons

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: onNextLevel) {
                HStack(spacing: AppSpacing.sm) {
                    Text("Next level")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16))
                }
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(height: 1)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .shadowL1()

            HStack(spacing: AppSpacing.md) {
                secondaryButton(icon: "arrow.counterclockwise", label: "Replay", action: onReplay)
                transparentButton(icon: "house", label: "Home", action: onHome)
            }
        }
    }

    private func secondaryButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon).font(.system(size: 16))
                Text(label)
            }
            .font(AppTypography.headlineSmall)
            .foregroundStyle(AppColors.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md - 2)
            .background(AppColors.surfaceContainerLowest)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .stroke(Color(hex: "#EDE6DA"), lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func transparentButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon).font(.system(size: 16))
                Text(label)
            }
            .font(AppTypography.headlineSmall)
            .foregroundStyle(AppColors.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md - 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: — Helpers

    private var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        LevelCompleteSheet(
            elapsedSeconds: 165,
            stars:          3,
            hintsUsed:      0,
            onNextLevel: {},
            onReplay:    {},
            onHome:      {}
        )
    }
}
