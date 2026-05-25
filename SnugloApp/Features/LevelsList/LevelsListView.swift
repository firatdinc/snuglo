import SwiftUI

// MARK: — LevelsListView (Screen 04)
// Design reference: Designs/html/04-levels-list.html
//
// "LEVELS" tab — shows pack cards: Cozy Beginnings / Spice Route / Mambo Nights / Woodland Retreat
// Tapping an unlocked pack → .packDetail(packId:)
// Faz G-1: IAP-locked packs are tappable and show unlock-prompt alert → Shop

struct LevelsListView: View {

    let packId: String  // "" = all packs (the tab view)

    @Environment(AppRouter.self) private var router

    /// Kilitli pack dokunumu için alert state
    @State private var lockedPackTitle: String = ""
    @State private var showLockedAlert: Bool   = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                packList
            }

            BottomTabBar()
        }
        .navigationBarHidden(true)
        .onAppear { router.selectedTab = .levels }
        // Faz G-1: Kilitli pack alert
        .alert("Unlock Pack", isPresented: $showLockedAlert) {
            Button("Go to Shop") {
                router.selectTab(.shop)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(lockedPackTitle) is locked. Visit the Shop to unlock it.")
        }
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            Button {
                router.push(.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Snuglo")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)

            Spacer()

            Button {
                router.selectTab(.shop)
            } label: {
                Image(systemName: "bag.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
    }

    // MARK: — Pack list

    private var packList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Levels")
                        .font(AppTypography.headlineLarge)
                        .foregroundStyle(AppColors.onSurface)
                        .tracking(-0.6)

                    Text("Pick a pack")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                // Pack cards — Faz D-2: PackProvider (wraps MockData, Faz E'de persistence)
                ForEach(PackProvider.allPacks()) { pack in
                    packCard(pack)
                }

                Spacer(minLength: 80) // clearance for tab bar
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: — Pack card

    @ViewBuilder
    private func packCard(_ pack: Pack) -> some View {
        let content = packCardContent(pack)

        if pack.isLocked {
            // Faz G-1: Kilitli packlar tıklanabilir → shop yönlendirme alertı
            Button {
                lockedPackTitle = pack.title
                showLockedAlert = true
            } label: {
                content
                    .opacity(0.55)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                router.push(.packDetail(packId: pack.id))
            } label: {
                content
            }
            .buttonStyle(.plain)
        }
    }

    private func packCardContent(_ pack: Pack) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(pack.title)
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)

                    // Grid badge
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "square.grid.3x3")
                            .font(.system(size: 12))
                        Text(pack.gridLabel)
                            .font(AppTypography.labelSmall)
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()

                // Icon tile
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
            }

            // Progress row
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(pack.isLocked ? "LOCKED" : "PROGRESS")
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
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadowL1()
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        LevelsListView(packId: "")
    }
    .environment(AppRouter())
}
