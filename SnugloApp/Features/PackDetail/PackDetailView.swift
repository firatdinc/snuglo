import SwiftUI
import Foundation

// MARK: — PackDetailView (Faz 3a: Vibrant Play restyle)
// Design reference: Designs/VibrantPlay/level-map.png
// Hero: Image("scene-island") full-width with gradient scrim + cardSurface info card.
// Level nodes: circles — completed: primary fill + white text; available: white + primary border; locked: surfaceContainerHigh.
// H-2: VoiceOver — each level tile has a full label (number, stars, status).

struct PackDetailView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let packName: String

    /// Live scroll position — drives the gradient backdrop. Updated via
    /// `onScrollGeometryChange` (NOT a GeometryReader+preference loop, which had
    /// frozen the screen on pop — see CLAUDE.md gotcha).
    @State private var scrollY: CGFloat = 0

    private var pack: Pack? {
        MockData.allPacks.first { $0.title == packName || $0.id == packName }
    }

    /// Themed scene + icon for this pack (shared table → matches the Levels card).
    private var theme: PackArt.Theme {
        PackArt.theme(forPackId: pack?.id ?? "")
    }
    private var sceneName: String { theme.scene }

    private var levels: [LevelItem] {
        guard let currentPack = pack else { return [] }
        return PackProvider.levelItems(in: currentPack.id)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner

                // Duolingo-style winding path of level nodes, over a parallax
                // layer of slow-drifting firefly lights.
                LazyVStack(spacing: AppSpacing.lg) {
                    ForEach(Array(levels.enumerated()), id: \.element.id) { idx, level in
                        levelNode(level)
                            .offset(x: pathOffset(idx))
                    }
                }
                .padding(.vertical, AppSpacing.xl)
                .background(
                    // Parallax driven by a LOCAL GeometryReader (no @State, no
                    // onPreferenceChange) — per-frame state writes during the pop
                    // animation were racing the NavigationStack and leaving the
                    // tab bar hit-test-disabled. Firefly drift is animated with a
                    // state-free TimelineView, so it never feeds the layout loop.
                    GeometryReader { geo in
                        firefliesLayer(
                            width: geo.size.width,
                            scrollY: geo.frame(in: .named("packScroll")).minY
                        )
                    }
                    .allowsHitTesting(false)
                )
            }
        }
        .coordinateSpace(name: "packScroll")
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
            scrollY = y
        }
        .background(parallaxBackground.ignoresSafeArea())
        .navigationTitle(pack?.localizedTitle ?? packName)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.packDetail")
    }

    // MARK: — Parallax gradient backdrop
    // Three soft theme-tinted gradients cross-fade as the player scrolls deeper,
    // giving a slow, smooth colour shift tied to scroll position.
    private var parallaxBackground: some View {
        let total = max(1, CGFloat(levels.count) * 100)
        let p = min(1, max(0, scrollY / total))   // 0 at top → 1 deep
        let phase = p * 2                          // 0 … 2
        return ZStack {
            AppColors.background
            gradient(AppColors.background, AppColors.primaryContainer.opacity(0.40))
                .opacity(max(0, 1 - phase))
            gradient(AppColors.blockSage.opacity(0.30), AppColors.background)
                .opacity(max(0, 1 - abs(phase - 1)))
            gradient(AppColors.blushAccent, AppColors.blockLavender.opacity(0.35))
                .opacity(max(0, phase - 1))
        }
        .animation(.easeOut(duration: 0.35), value: scrollY)
    }

    private func gradient(_ a: Color, _ b: Color) -> some View {
        LinearGradient(colors: [a, b], startPoint: .top, endPoint: .bottom)
    }

    /// Smooth sine-wave horizontal offset → the iconic Duolingo winding path.
    private func pathOffset(_ index: Int) -> CGFloat {
        let amplitude: CGFloat = 70
        return amplitude * CGFloat(sin(Double(index) * 0.8))
    }

    // MARK: — Ambient fireflies (parallax glowing lights)

    private struct Firefly: Identifiable {
        let id: Int
        let xFrac: CGFloat      // 0…1 across the width
        let baseY: CGFloat
        let size: CGFloat
        let color: Color
        let baseOpacity: Double
        let parallax: CGFloat   // depth: smaller = further away, drifts slower
        let phase: CGFloat
        let speed: CGFloat
        let wander: CGFloat     // px radius of the slow drift
    }

    private var fireflies: [Firefly] {
        // Warm, glowy palette — strictly AppColors tokens (single-palette rule).
        let palette: [Color] = [
            AppColors.tertiary, AppColors.blockPeach, AppColors.blockLavender, AppColors.blockSage
        ]
        let sizes: [CGFloat] = [6, 9, 5, 11, 7, 8]
        let factors: [CGFloat] = [0.12, 0.22, 0.32, 0.42]
        let opacities: [Double] = [0.9, 0.7, 1.0, 0.65]
        // A sparser, magical field — fewer than the old icon clutter.
        let count = max(12, Int(Double(levels.count) * 1.4))
        return (0..<count).map { i in
            // Golden-ratio low-discrepancy sequence → even, organic spread.
            let r = CGFloat((Double(i) * 0.6180339887).truncatingRemainder(dividingBy: 1))
            let r2 = CGFloat((Double(i) * 0.7548776662).truncatingRemainder(dividingBy: 1))
            return Firefly(
                id: i,
                xFrac: 0.10 + r * 0.80,
                baseY: 220 + CGFloat(i) * 96 + r2 * 60,
                size: sizes[i % sizes.count],
                color: palette[i % palette.count],
                baseOpacity: opacities[i % opacities.count],
                parallax: factors[i % factors.count],
                phase: r * 6.2831853,
                speed: 0.22 + r2 * 0.30,
                wander: 16 + r * 24
            )
        }
    }

    /// Fireflies drift slowly via a state-free `TimelineView` (no @State writes →
    /// safe from the scroll/pop layout loop). They also move with `scrollY` from a
    /// local GeometryReader, so deeper ones lag → parallax depth. Respects Reduce
    /// Motion: static, softly glowing when motion is reduced.
    private func firefliesLayer(width: CGFloat, scrollY: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(fireflies) { f in
                    let dx = reduceMotion ? 0 : f.wander * CGFloat(sin(t * Double(f.speed) + Double(f.phase)))
                    let dy = reduceMotion ? 0 : f.wander * 0.65 * CGFloat(cos(t * Double(f.speed) * 0.8 + Double(f.phase)))
                    let pulse = reduceMotion ? 1.0 : 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 1.7 + Double(f.phase) * 2))
                    firefly(f)
                        .opacity(f.baseOpacity * pulse)
                        .position(
                            x: width * f.xFrac + dx,
                            y: f.baseY + dy - scrollY * f.parallax
                        )
                }
            }
        }
    }

    /// A single firefly: a soft blurred halo + a bright hot core.
    @ViewBuilder
    private func firefly(_ f: Firefly) -> some View {
        ZStack {
            Circle()
                .fill(f.color)
                .frame(width: f.size * 3.2, height: f.size * 3.2)
                .blur(radius: f.size * 1.5)
                .opacity(0.5)
            Circle()
                .fill(f.color)
                .frame(width: f.size, height: f.size)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: f.size * 0.42, height: f.size * 0.42)
                        .blur(radius: 0.5)
                        .opacity(0.75)
                )
        }
        .accessibilityHidden(true)
    }

    // MARK: — Hero banner (image first, info card BELOW it — fully visible)

    /// Localized difficulty label derived from the pack's grid size.
    private func difficultyKey(for gridSize: Int) -> LocalizedStringKey {
        switch gridSize {
        case ...5: return "pack.difficulty.beginner"
        case 6:    return "pack.difficulty.easy"
        case 7:    return "pack.difficulty.medium"
        default:   return "pack.difficulty.hard"
        }
    }

    private var heroBanner: some View {
        VStack(spacing: 0) {
            // Generous hero — scaledToFit (no crop), large height so the island
            // scene reads as the screen's focal point.
            Image(sceneName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .accessibilityHidden(true)

            if let packData = pack {
                // Live progress (MockData.completedCount is a static scaffold value).
                let completed = ProgressStore.shared.packCompletionCount(packData.id)
                let starsEarned = ProgressStore.shared.packStarsEarned(packData.id)
                let starsMax = packData.levelCount * 3
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Label(difficultyKey(for: packData.gridSize), systemImage: "sparkles")
                            .font(AppTypography.labelSmall)
                            .tracking(0.6)
                            .textCase(.uppercase)
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, AppSpacing.sm + 4)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primaryContainer.opacity(0.4), in: Capsule())
                            .accessibilityHidden(true)
                        Spacer()
                        if completed >= packData.levelCount {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(AppColors.tertiary)
                                .accessibilityHidden(true)
                        }
                    }

                    HStack(alignment: .center, spacing: AppSpacing.sm) {
                        Image(theme.art)
                            .resizable().renderingMode(.original).scaledToFit()
                            .frame(width: 44, height: 44)
                            .accessibilityHidden(true)
                        Text(packData.titleKey)
                            .font(AppTypography.headlineLarge)
                            .tracking(-0.6)
                            .foregroundStyle(AppColors.onSurface)
                    }

                    Text(packData.gridLabelKey)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)

                    HStack(spacing: AppSpacing.sm) {
                        GameProgressBar(
                            progress: Double(completed) / Double(packData.levelCount),
                            height: 12
                        )
                        Text("\(completed)/\(packData.levelCount)")
                            .font(AppTypography.numericSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.levelsCompleted", comment: ""), completed, packData.levelCount)))

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.tertiary)
                        Text(verbatim: "\(starsEarned)/\(starsMax)")
                            .font(AppTypography.numericSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .monospacedDigit()
                    }
                    .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.starsEarned", comment: ""), starsEarned, starsMax)))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .cardSurface()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
        }
    }

    // MARK: — Level node (Duolingo-style 3D raised disc + stars below)

    private let nodeSize: CGFloat = 66
    private let nodeDepth: CGFloat = 6

    @ViewBuilder
    private func levelNode(_ level: LevelItem) -> some View {
        Button {
            guard !level.isLocked else { return }
            router.push(.game(levelID: level.id))
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Bottom slab → 3D depth.
                    Circle()
                        .fill(nodeBottomColor(level))
                        .frame(width: nodeSize, height: nodeSize)
                        .offset(y: nodeDepth)
                    // Top face.
                    Circle()
                        .fill(nodeTopColor(level))
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(
                            Circle().strokeBorder(nodeBorderColor(level), lineWidth: 2)
                        )
                    // Centred content — perfectly centred number / icon.
                    nodeContent(level)
                }
                .frame(width: nodeSize, height: nodeSize + nodeDepth, alignment: .top)

                starsRow(level)
            }
        }
        .buttonStyle(NodePressStyle(depth: nodeDepth))
        .disabled(level.isLocked)
        .accessibilityLabel(levelTileA11yLabel(level))
        .accessibilityHint(Text(level.isLocked ? "" : "a11y.tapToPlay"))
        .accessibilityIdentifier("packdetail.level_item.\(level.index - 1)")
    }

    @ViewBuilder
    private func nodeContent(_ level: LevelItem) -> some View {
        if level.isLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                .accessibilityHidden(true)
        } else {
            Text("\(level.index)")
                .font(AppTypography.numericLabel)
                .foregroundStyle(level.isCompleted ? .white : AppColors.onSurface)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func starsRow(_ level: LevelItem) -> some View {
        if level.isLocked {
            // Reserve the same vertical space so the path rhythm stays even.
            Color.clear.frame(height: 11)
        } else {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { starIdx in
                    Image(systemName: starIdx < level.stars ? "star.fill" : "star")
                        .font(.system(size: 9))
                        .foregroundStyle(starIdx < level.stars
                                         ? AppColors.tertiary
                                         : AppColors.outlineVariant.opacity(0.5))
                }
            }
            .frame(height: 11)
            .accessibilityHidden(true)
        }
    }

    // MARK: — Node colors

    private func nodeTopColor(_ level: LevelItem) -> Color {
        if level.isCompleted { return AppColors.primary }
        if level.isLocked { return AppColors.surfaceContainerHigh }
        return AppColors.surfaceContainerLowest
    }

    private func nodeBottomColor(_ level: LevelItem) -> Color {
        if level.isCompleted { return AppColors.primaryPressed }
        if level.isLocked { return AppColors.outlineVariant.opacity(0.4) }
        return AppColors.outlineVariant
    }

    private func nodeBorderColor(_ level: LevelItem) -> Color {
        if level.isCompleted { return .clear }
        if level.isLocked { return AppColors.outlineVariant.opacity(0.3) }
        return AppColors.primary.opacity(0.5)
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

}

// MARK: — NodePressStyle
// Duolingo-style press: the whole node sinks onto its 3D slab when pressed.

private struct NodePressStyle: ButtonStyle {
    let depth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: reduceMotion ? 0 : (configuration.isPressed ? depth : 0))
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        PackDetailView(packName: "Cozy Beginnings")
    }
    .environment(AppRouter())
}
