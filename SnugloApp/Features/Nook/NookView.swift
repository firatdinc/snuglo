import SwiftUI

// MARK: — NookView
// The cozy meta-layer as scene restoration. Each campaign pack owns a transparent,
// island-shaped scene that starts as a solid BLACK silhouette, broken like glass
// into 6 irregular shards. Every 10 levels the player earns one shard; in here they
// DRAG it (a colour piece cut to its shard) onto its dark slot — like placing a
// block in-game — and that shard blooms into full colour with a flash, a snap and a
// haptic. Restore all 6 and the pack's mascot appears in the finished scene. Pieces
// earned are derived live from campaign progress (NookStore); only placements are
// persisted.

struct NookView: View {

    @Environment(AppRouter.self) private var router

    @State private var store = NookStore.shared
    @State private var selectedPackId = ""

    // Drag state (coordinates in the "nook" coordinate space).
    @State private var canvasFrame: CGRect = .zero
    @State private var dragging = false
    @State private var dragLocation: CGPoint = .zero
    @State private var justRevealed: Int?
    @State private var revealFlash = 0.0
    @State private var showConfetti = false
    @State private var targetPulse = false

    private static let nookSpace = "nook.canvas.space"
    private let canvasHeight: CGFloat = 300
    private let pieceHeight: CGFloat = 86

    private var packs: [Pack] { MockData.allPacks }
    private var scene: String { PackArt.theme(forPackId: selectedPackId).scene }
    private var placedN: Int { store.placedPieces(selectedPackId) }
    private var available: Int { store.availablePieces(selectedPackId) }
    private var restored: Bool { store.isRestored(selectedPackId) }
    private var pieceBase: CGSize {
        canvasFrame == .zero ? CGSize(width: 300, height: canvasHeight) : canvasFrame.size
    }

    var body: some View {
        ZStack {
            VStack(spacing: AppSpacing.md) {
                packStrip
                restorationCanvas
                trayArea
                footer
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)

            if dragging, available > 0 {
                ShardPieceView(scene: scene, shardIndex: placedN, base: pieceBase, displayHeight: pieceHeight)
                    .scaleEffect(1.15)
                    .shadow(color: AppColors.shadowAmbient.opacity(0.4), radius: 12, y: 6)
                    .position(dragLocation)
                    .allowsHitTesting(false)
            }
            if showConfetti {
                SolveCelebration(intensity: 0.85).allowsHitTesting(false)
            }
        }
        .coordinateSpace(.named(Self.nookSpace))
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("nook.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: pickDefaultPack)
        .onAppear {
            guard !targetPulse else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                targetPulse = true
            }
        }
        // If the player leaves the Nook without placing, drop the milestone
        // auto-return flag so it can't leak into a later, normal Nook visit.
        .onDisappear { NookRevealCenter.shared.autoReturnOnPlace = false }
    }

    // MARK: — Pack strip

    private var packStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(packs) { pack in
                    let isSel = pack.id == selectedPackId
                    Button {
                        HapticService.shared.impact(.light)
                        withAnimation(AppMotion.card) { selectedPackId = pack.id }
                    } label: {
                        VStack(spacing: 5) {
                            RestoreThumb(scene: PackArt.theme(forPackId: pack.id).scene,
                                         placed: store.placedPieces(pack.id))
                                .frame(width: 78, height: 52)
                                .background(AppColors.surfaceContainerHigh,
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(isSel ? AppColors.primary : AppColors.outlineVariant.opacity(0.5),
                                                      lineWidth: isSel ? 2.5 : 1)
                                )
                                .overlay(alignment: .topTrailing) {
                                    if store.availablePieces(pack.id) > 0 {
                                        Circle().fill(AppColors.tertiary)
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().strokeBorder(AppColors.onTertiary, lineWidth: 1.5))
                                            .offset(x: 4, y: -4)
                                    }
                                }
                            Text(verbatim: "\(store.placedPieces(pack.id))/\(NookStore.piecesPerScene)")
                                .font(AppTypography.numericSmall).monospacedDigit()
                                .foregroundStyle(isSel ? AppColors.primary : AppColors.onSurfaceVariant)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: — Restoration canvas

    private var restorationCanvas: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Full-colour scene base. The dark shards sit ON TOP of it, so
                // revealing a shard just lifts the black cover off the very same
                // pixels — it always lines up perfectly (no offset, "tam oturur").
                Image(scene).resizable().scaledToFit()
                    .frame(width: size.width, height: size.height)

                // Not-yet-placed shards: the same image blacked out, cut to each
                // shard. Same image + same fit as the base → zero misalignment.
                ForEach(Array(placedN..<ShardGeometry.count), id: \.self) { i in
                    Image(scene).resizable().scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .colorMultiply(.black)
                        .mask(ShardShape(points: ShardGeometry.shards[i]))
                        .transition(.opacity)
                }

                // Bright flash over the shard that was just placed.
                if let j = justRevealed {
                    ShardShape(points: ShardGeometry.shards[j])
                        .fill(AppColors.onPrimary)
                        .opacity(revealFlash)
                        .allowsHitTesting(false)
                }

                // Faint crack lines so the shatter pattern always reads.
                ForEach(0..<ShardGeometry.count, id: \.self) { i in
                    ShardShape(points: ShardGeometry.shards[i])
                        .stroke(AppColors.onPrimary.opacity(0.16), lineWidth: 1)
                }

                // Pulsing target for the next shard.
                if available > 0, placedN < ShardGeometry.count {
                    let shard = ShardGeometry.shards[placedN]
                    ShardShape(points: shard)
                        .fill(AppColors.tertiary.opacity(targetPulse ? 0.20 : 0.06))
                    ShardShape(points: shard)
                        .stroke(AppColors.tertiary, style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
                        .opacity(targetPulse ? 1 : 0.45)
                }

                if restored {
                    Image(PackArt.theme(forPackId: selectedPackId).art)
                        .resizable().scaledToFit()
                        .frame(width: 60, height: 60)
                        .shadow(color: AppColors.shadowAmbient.opacity(0.4), radius: 4, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, AppSpacing.sm)
                    restoredSeal
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(AppSpacing.sm)
                }
            }
            .onAppear { canvasFrame = geo.frame(in: .named(Self.nookSpace)) }
            .animation(AppMotion.card, value: placedN)
        }
        .frame(height: canvasHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .cardSurface()
    }

    private var restoredSeal: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 13, weight: .bold))
            Text("nook.restored.badge").font(AppTypography.labelSmall)
        }
        .foregroundStyle(AppColors.onTertiary)
        .padding(.horizontal, AppSpacing.sm).padding(.vertical, 5)
        .background(AppColors.tertiary, in: Capsule())
        .shadow(color: AppColors.shadowAmbient.opacity(0.25), radius: 4, y: 2)
    }

    // MARK: — Tray

    @ViewBuilder
    private var trayArea: some View {
        if available > 0 {
            HStack(spacing: AppSpacing.md) {
                ShardPieceView(scene: scene, shardIndex: placedN, base: pieceBase, displayHeight: pieceHeight)
                    .opacity(dragging ? 0.25 : 1)
                    .shadow(color: AppColors.shadowAmbient.opacity(0.3), radius: 4, y: 3)
                    .gesture(pieceDrag)
                VStack(alignment: .leading, spacing: 4) {
                    Text("nook.drag.hint")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Text(verbatim: String(format: NSLocalizedString("nook.pieces.ready", comment: ""), available))
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.tertiary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .cardSurface()
        } else if restored {
            trayMessage(icon: "sparkles", text: "nook.scene.done", tint: AppColors.primary)
        } else {
            trayMessage(icon: "lock.fill",
                        text: LocalizedStringKey(String(format: NSLocalizedString("nook.locked.hint", comment: ""), levelsToNextPiece)),
                        tint: AppColors.onSurfaceVariant)
        }
    }

    private func trayMessage(icon: String, text: LocalizedStringKey, tint: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(tint)
            Text(text).font(AppTypography.bodyMedium).foregroundStyle(AppColors.onSurface)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .cardSurface()
    }

    // MARK: — Footer

    private var footer: some View {
        let pct = Int((store.completion * 100).rounded())
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label(
                    title: { Text(verbatim: String(format: NSLocalizedString("nook.world.restored", comment: ""), pct)) },
                    icon: { Image(systemName: "globe.americas.fill") }
                )
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
                Spacer()
                Text(verbatim: "\(store.unlockedMascotCount)/\(packs.count)")
                    .font(AppTypography.numericSmall).monospacedDigit()
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.surfaceContainerHigh)
                    Capsule()
                        .fill(LinearGradient(colors: [AppColors.tertiary, AppColors.primary],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, geo.size.width * CGFloat(store.completion)))
                }
            }
            .frame(height: 12)
            .animation(AppMotion.card, value: store.completion)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .cardSurface()
    }

    // MARK: — Drag gesture

    private var pieceDrag: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.nookSpace))
            .onChanged { value in
                if !dragging { HapticService.shared.prepareImpact() }
                dragging = true
                dragLocation = value.location
            }
            .onEnded { value in
                if hitsTarget(value.location) {
                    commitPlace()
                } else {
                    HapticService.shared.impact(.light)
                }
                dragging = false
            }
    }

    private func hitsTarget(_ loc: CGPoint) -> Bool {
        guard canvasFrame.width > 0, placedN < ShardGeometry.count else { return false }
        let n = CGPoint(x: (loc.x - canvasFrame.minX) / canvasFrame.width,
                        y: (loc.y - canvasFrame.minY) / canvasFrame.height)
        return ShardGeometry.contains(ShardGeometry.shards[placedN], n)
    }

    private func commitPlace() {
        guard let idx = store.placeNextPiece(selectedPackId) else { return }
        justRevealed = idx
        // White flash over the freshly-revealed shard, fading out. The black cover
        // removal itself animates via the canvas .animation(value: placedN).
        revealFlash = 0.9
        withAnimation(.easeOut(duration: 0.6)) { revealFlash = 0 }
        SoundService.shared.play(.snap)
        HapticService.shared.impact(.medium)

        let restored = store.isRestored(selectedPackId)
        if restored {
            SoundService.shared.play(.reward)
            HapticService.shared.notify(.success)
            showConfetti = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.4))
                showConfetti = false
            }
        }

        // Milestone flow: the player came straight from a level-complete to place
        // this piece — auto-return to the game so they aren't stranded here. (Normal
        // Nook visits from the menu leave the flag false → no auto-return.)
        if NookRevealCenter.shared.autoReturnOnPlace {
            NookRevealCenter.shared.autoReturnOnPlace = false
            let delay = restored ? 2.6 : 1.2   // let the reveal / confetti land first
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                router.pop()
            }
        }
    }

    // MARK: — Default selection + lock hint

    private func pickDefaultPack() {
        guard selectedPackId.isEmpty else { return }
        if let ready = packs.first(where: { store.availablePieces($0.id) > 0 }) {
            selectedPackId = ready.id
        } else if let inProgress = packs.first(where: { !store.isRestored($0.id) }) {
            selectedPackId = inProgress.id
        } else {
            selectedPackId = packs.first?.id ?? ""
        }
    }

    private var levelsToNextPiece: Int {
        let done = ProgressStore.shared.packCompletionCount(selectedPackId)
        let earned = store.earnedPieces(selectedPackId)
        guard earned < NookStore.piecesPerScene else { return 0 }
        return max(1, (earned + 1) * NookStore.levelsPerPiece - done)
    }
}

// MARK: — RestoreThumb (mini scene preview for the pack strip)

private struct RestoreThumb: View {
    let scene: String
    let placed: Int

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let start = min(placed, ShardGeometry.count)
            ZStack {
                // Colour base + black covers on the unrevealed shards (same flip as
                // the big canvas → revealed shards line up exactly).
                Image(scene).resizable().scaledToFit()
                    .frame(width: size.width, height: size.height)
                ForEach(Array(start..<ShardGeometry.count), id: \.self) { i in
                    Image(scene).resizable().scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .colorMultiply(.black)
                        .mask(ShardShape(points: ShardGeometry.shards[i]))
                }
            }
        }
    }
}
