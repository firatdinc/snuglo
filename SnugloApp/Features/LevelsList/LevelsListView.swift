import SwiftUI

// MARK: — LevelsListView (Screen 04 · Faz 3a: Vibrant Play restyle · H-1: Localized)
// Design reference: Designs/VibrantPlay/levels-list.png
// Pack cards use CardSurface (white, 20pt radius, L1 shadow). Real pack/level data only.
// H-2: VoiceOver — pack cards with progress/locked status, top-bar buttons labelled.

struct LevelsListView: View {

    let packId: String  // "" = all packs (the tab view)

    @Environment(AppRouter.self) private var router

    @State private var lockedPackTitle: String = ""
    @State private var showLockedAlert: Bool   = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                packList
            }

        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.levels")
        .alert("alert.unlockPack.title", isPresented: $showLockedAlert) {
            Button("alert.unlockPack.goToShop") {
                router.selectTab(.shop)
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(verbatim: String(format: NSLocalizedString("alert.unlockPack.message", comment: ""), lockedPackTitle))
        }
    }

    // MARK: — Pack list

    private var packList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("levels.title")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)

                    Text("levels.subtitle")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                ForEach(PackProvider.allPacks()) { pack in
                    packCard(pack)
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: — Pack card

    @ViewBuilder
    private func packCard(_ pack: Pack) -> some View {
        let content = packCardContent(pack)

        // H-2: accessibility label built from pack info
        let a11yLabel = packA11yLabel(pack)

        if pack.isLocked {
            Button {
                lockedPackTitle = pack.localizedTitle
                showLockedAlert = true
            } label: {
                content
                    .opacity(0.55)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(a11yLabel)
            .accessibilityHint("Tap to unlock this pack in the shop")
        } else {
            Button {
                router.push(.packDetail(packId: pack.id))
            } label: {
                content
            }
            .buttonStyle(.plain)
            .accessibilityLabel(a11yLabel)
            .accessibilityHint("Opens the level list for this pack")
        }
    }

    /// H-2: Constructs a meaningful VoiceOver label for a pack card.
    private func packA11yLabel(_ pack: Pack) -> String {
        if pack.isLocked {
            return "\(pack.localizedTitle). Locked. Tap to unlock."
        }
        let pct = Int(pack.progressFraction * 100)
        return "\(pack.localizedTitle), \(pack.completedCount) of \(pack.levelCount) levels completed, \(pct) percent"
    }

    private func packCardContent(_ pack: Pack) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(pack.titleKey)
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "square.grid.3x3")
                            .font(.system(size: 12))
                            .accessibilityHidden(true)
                        Text(verbatim: pack.gridLabel)
                            .font(AppTypography.labelSmall)
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(pack.isLocked ? AppColors.surfaceContainerHigh : pack.accentColor.opacity(0.5))
                        .frame(width: 48, height: 48)

                    if pack.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    } else {
                        Image(systemName: pack.iconSymbol)
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .accessibilityHidden(true) // icon is decorative; label on button
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(pack.isLocked ? "pack.locked" : "pack.progress")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.onSurfaceVariant)

                    Spacer()

                    HStack(spacing: 2) {
                        Text("\(pack.completedCount)")
                            .font(AppTypography.numericLabel)
                            .foregroundStyle(pack.isLocked ? AppColors.onSurfaceVariant : AppColors.primary)

                        Text("/\(pack.levelCount)")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 99, style: .continuous)
                            .fill(AppColors.surfaceContainerHigh)
                            .frame(height: 12)

                        if !pack.isLocked && pack.progressFraction > 0 {
                            RoundedRectangle(cornerRadius: 99, style: .continuous)
                                .fill(AppColors.primary)
                                .frame(width: geo.size.width * pack.progressFraction, height: 12)
                        }
                    }
                }
                .frame(height: 12)
                .accessibilityHidden(true) // progress conveyed in button label
            }
        }
        .padding(AppSpacing.md)
        .cardSurface()
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        LevelsListView(packId: "")
    }
    .environment(AppRouter())
}
