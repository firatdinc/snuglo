import SwiftUI

// MARK: — NookPieceRevealOverlay
// The milestone surprise. A wrapped "egg" wobbles with anticipation, then bursts
// open with confetti to reveal the scene piece the player just earned. They can
// jump straight to the Nook to drag it in, or save it for later. Mirrors the
// RewardPopup presentation pattern; shown from RootView when NookRevealCenter has
// a pending reveal. Reduce-Motion safe (skips the wobble + shortens the wait).

struct NookPieceRevealOverlay: View {

    let reveal: NookRevealCenter.Reveal
    var onPlace: () -> Void
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var opened = false
    @State private var burst = false
    @State private var wobble = false
    @State private var sunSpin = false
    @State private var pieceScale: CGFloat = 0.2

    private var scene: String { PackArt.theme(forPackId: reveal.packId).scene }

    var body: some View {
        ZStack {
            AppColors.shadowAmbient.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture { if opened { onDismiss() } }

            if burst {
                SolveCelebration(intensity: 0.9).allowsHitTesting(false)
            }

            Group {
                if opened { revealCard } else { egg }
            }
            .padding(AppSpacing.xl)
        }
        .task { await run() }
    }

    // MARK: — Anticipation egg

    private var egg: some View {
        ZStack {
            // Rotating sunburst behind the egg.
            Image(systemName: "sparkles")
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(AppColors.tertiary.opacity(0.5))
                .rotationEffect(.degrees(sunSpin ? 360 : 0))

            Circle()
                .fill(LinearGradient(colors: [AppColors.tertiaryContainer, AppColors.tertiary],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "gift.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(AppColors.onTertiary)
                )
                .shadow(color: AppColors.shadowAmbient.opacity(0.4), radius: 14, y: 8)
                .rotationEffect(.degrees(wobble ? 7 : -7))
                .scaleEffect(wobble ? 1.06 : 0.97)
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { sunSpin = true }
        }
    }

    // MARK: — Reveal card

    private var revealCard: some View {
        VStack(spacing: AppSpacing.md) {
            Text("nook.reveal.title")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)

            ShardPieceView(scene: scene, shardIndex: reveal.pieceIndex,
                           base: CGSize(width: 300, height: 220), displayHeight: 132)
                .scaleEffect(pieceScale)
                .shadow(color: AppColors.shadowAmbient.opacity(0.4), radius: 12, y: 6)

            Text("nook.reveal.subtitle")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)

            HStack(spacing: AppSpacing.sm) {
                Button(action: onDismiss) {
                    Text("nook.reveal.later")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surfaceContainerHigh, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onPlace) {
                    Text("nook.reveal.place")
                        .font(AppTypography.bodyLarge.weight(.semibold))
                        .foregroundStyle(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: 340)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .cardSurface()
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    // MARK: — Choreography

    private func run() async {
        SoundService.shared.play(.click)
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.16).repeatCount(6, autoreverses: true)) {
                wobble = true
            }
            HapticService.shared.impact(.light)
        }
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.05))

        SoundService.shared.play(.reward)
        HapticService.shared.notify(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
            opened = true
            burst = true
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.08)) {
            pieceScale = 1
        }
    }
}
