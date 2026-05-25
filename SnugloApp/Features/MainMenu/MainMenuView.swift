import SwiftUI

// MARK: — MainMenuView (Screen 03 · H-1: Localized)
// Design reference: Designs/html/03-main-menu.html
// H-2: VoiceOver — daily puzzle card labelled, progress pill labelled, top-bar buttons hinted.

struct MainMenuView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                scrollContent
            }

            BottomTabBar()
        }
        .navigationBarHidden(true)
        .accessibilityIdentifier("screen.mainMenu")
        .onAppear { router.selectedTab = .play }
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
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens the settings screen")

            Spacer()

            Text("app.name")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.primary)
                .tracking(-0.4)
                .accessibilityHidden(true) // App name — not useful to repeat on every screen

            Spacer()

            Button {
                router.selectTab(.shop)
            } label: {
                Image(systemName: "bag.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Shop")
            .accessibilityHint("Opens the in-app shop")
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
    }

    // MARK: — Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {
                progressPill
                dailyPuzzleCard
                continueSection
                Spacer(minLength: 80) // clearance for tab bar
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: — Progress pill

    private var progressPill: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.tertiary)
                .accessibilityHidden(true)

            Text(verbatim: "Level 12")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
            +
            Text(verbatim: " / 240")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs + 2)
        .background(AppColors.surfaceContainer)
        .overlay(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .stroke(AppColors.surfaceContainerHigh, lineWidth: 1.5)
        )
        .clipShape(Capsule())
        .shadowL1()
        // H-2: combined element for VoiceOver
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level 12 of 240 completed")
    }

    // MARK: — Daily Puzzle card

    private var dailyGridSize: Int { PackProvider.dailyPuzzle().width }

    /// H-1 BLOCKER 2: real locale-aware countdown to next midnight.
    private var refreshCountdownString: String {
        let cal = Calendar.current
        let now = Date()
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) else {
            return "—"
        }
        let fmt = DateComponentsFormatter()
        fmt.unitsStyle = .abbreviated
        fmt.allowedUnits = [.hour, .minute]
        fmt.calendar = cal
        return fmt.string(from: now, to: tomorrow) ?? "—"
    }

    private var dailyDateBadge: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }

    private var dailyPuzzleCard: some View {
        Button {
            router.push(.gamePlay(levelId: "daily"))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image placeholder (decorative gradient)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.primaryContainer.opacity(0.4),
                                    AppColors.blockSage.opacity(0.2)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .frame(height: 140)
                        .accessibilityHidden(true)

                    // Date badge
                    Text(verbatim: dailyDateBadge)
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.background.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(AppSpacing.md)
                        .accessibilityHidden(true) // conveyed in card label

                    // GridSize indicator
                    Text(verbatim: "\(dailyGridSize)×\(dailyGridSize)")
                        .font(AppTypography.labelSmall)
                        .tracking(0.4)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm + 4)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primaryContainer.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .accessibilityHidden(true) // conveyed in card label
                }

                // Card content
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("menu.dailyPuzzle")
                            .font(AppTypography.headlineLarge)
                            .foregroundStyle(AppColors.onSurface)
                            .tracking(-0.6)

                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .accessibilityHidden(true)
                            // H-1 BLOCKER 2: real countdown + localized format
                            Text(verbatim: String(
                                format: NSLocalizedString("menu.refresh", comment: ""),
                                refreshCountdownString
                            ))
                            .font(AppTypography.bodyMedium)
                        }
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    Spacer()

                    // Play button (decorative — button handles tap)
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.primaryContainer)
                            .frame(width: 56, height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                                    .offset(y: -0.5)
                            )
                            .shadowL1()

                        Image(systemName: "play.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityHidden(true)
                }
                .padding(AppSpacing.md + 4)
                .background(AppColors.background)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            )
            .shadowL1()
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        // H-2: meaningful label for VoiceOver
        .accessibilityLabel(Text("menu.dailyPuzzle"))
        .accessibilityHint("Tap to play today's puzzle")
        // Faz I-2: UITest smoke identifier
        .accessibilityIdentifier("mainmenu.daily_card")
    }

    // MARK: — Continue section

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("menu.continue")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)

                Spacer()

                Button {
                    router.selectTab(.levels)
                } label: {
                    Text("menu.viewAll")
                        .font(AppTypography.labelSmall)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityLabel("View all level packs")
            }
            .padding(.horizontal, AppSpacing.xs)

            if let pack = MockData.continuePack, let level = MockData.continueLevel {
                continueCard(pack: pack, level: level)
            } else {
                Button {
                    router.selectTab(.levels)
                } label: {
                    HStack {
                        Text("menu.startFirst")
                            .font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppColors.primary)
                            .accessibilityHidden(true)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.primaryContainer.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the levels list to start your first puzzle")
            }
        }
    }

    private func continueCard(pack: Pack, level: LevelItem) -> some View {
        Button {
            router.push(.gamePlay(levelId: level.id))
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Pack thumbnail (decorative — label conveys pack info)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(pack.accentColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.surfaceContainerHigh, lineWidth: 1)
                        )

                    Image(systemName: pack.iconSymbol)
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.primary.opacity(0.7))
                }
                .accessibilityHidden(true)

                // Info
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(verbatim: pack.title)
                            .font(AppTypography.headlineMedium)
                            .foregroundStyle(AppColors.onSurface)
                            .lineLimit(1)

                        Text(verbatim: "Level \(level.number)")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    // Progress bar
                    HStack(spacing: AppSpacing.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 99, style: .continuous)
                                    .fill(AppColors.surfaceContainerHighest)
                                    .frame(height: 10)

                                RoundedRectangle(cornerRadius: 99, style: .continuous)
                                    .fill(AppColors.primaryContainer)
                                    .frame(width: geo.size.width * pack.progressFraction, height: 10)
                            }
                        }
                        .frame(height: 10)

                        Text(verbatim: "\(Int(pack.progressFraction * 100))%")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .accessibilityHidden(true) // conveyed by card label
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            )
            .shadowL1()
        }
        .buttonStyle(.plain)
        // H-2: combined label with progress context
        .accessibilityLabel("\(pack.title), Level \(level.number), \(Int(pack.progressFraction * 100)) percent complete")
        .accessibilityHint("Tap to continue this level")
        // Faz I-2: UITest primary play/continue CTA identifier
        .accessibilityIdentifier("mainmenu.play_cta")
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        MainMenuView()
    }
    .environment(AppRouter())
}
