import SwiftUI

// MARK: — SpinWheelOverlay
// The once-per-day fortune wheel. Spins with a long ease-out to a weighted-random
// segment, then reveals the reward. Self-contained, single-palette, Reduce-Motion
// safe (lands instantly, no long spin).

struct SpinWheelOverlay: View {
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var wonIndex: Int?
    @State private var showCelebration = false
    @State private var adShown = false

    private let colors: [Color] = [
        AppColors.primary, AppColors.tertiary, AppColors.secondary, AppColors.blockLavender,
        AppColors.blockPeach, AppColors.blockSage, AppColors.primaryContainer, AppColors.tertiaryContainer,
    ]

    private func label(_ i: Int) -> String {
        let s = SpinStore.segments[i]
        switch s.currency {
        case .gem:    return "💎\(s.amount)"
        case .ticket: return "🎟\(s.amount)"
        default:      return "\(s.amount)"
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.opacity(0.6).ignoresSafeArea()
                .onTapGesture { if wonIndex != nil { onClose() } }

            if showCelebration && !reduceMotion {
                let seg = wonIndex.map { SpinStore.segments[$0] }
                SolveCelebration(intensity: RewardTierFX.intensity(
                    coins: seg?.currency == .gem ? 0 : (seg?.amount ?? 0),
                    gems: seg?.currency == .gem ? (seg?.amount ?? 0) : 0
                )).allowsHitTesting(false)
            }

            VStack(spacing: AppSpacing.lg) {
                Text("spin.title")
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(AppColors.onSurface)

                ZStack {
                    wheel
                        .frame(width: 272, height: 272)
                        .rotationEffect(.degrees(rotation))
                    // fixed pointer at the top
                    Triangle()
                        .fill(AppColors.onSurface)
                        .frame(width: 22, height: 20)
                        .offset(y: -148)
                        .shadow(radius: 2)
                }

                if let i = wonIndex {
                    VStack(spacing: 2) {
                        Text("spin.reward").font(AppTypography.labelSmall).textCase(.uppercase)
                            .tracking(0.6).foregroundStyle(AppColors.onSurfaceVariant)
                        Text(verbatim: "+\(label(i))").font(AppTypography.headlineMedium)
                            .foregroundStyle(AppColors.onSurface)
                    }
                    .transition(.scale.combined(with: .opacity))

                    if !adShown {
                        let canAd = AdsManager.shared.rewardedAvailable
                        Button {
                            guard canAd else { return }
                            let seg = SpinStore.segments[i]
                            AdsManager.shared.showRewarded {
                                WalletStore.shared.earn(seg.currency, amount: seg.amount)
                                RewardCenter.shared.showCurrency(seg.currency, amount: seg.amount)
                                HapticService.shared.notify(.success)
                                onClose()
                            }
                            adShown = true
                        } label: {
                            Label(canAd ? "reward.double" : "shop.claim.adNotReady",
                                  systemImage: "play.rectangle.fill")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(canAd ? AppColors.primary : AppColors.onSurfaceVariant)
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, AppSpacing.sm)
                                .overlay(Capsule().stroke(canAd ? AppColors.primary : AppColors.outlineVariant, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAd)
                    }
                    RewardButton(titleKey: "spin.collect", action: onClose)
                } else {
                    Button(action: spin) {
                        Text("spin.spin").font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.onPrimary)
                            .padding(.horizontal, AppSpacing.xl + 8).padding(.vertical, AppSpacing.sm + 2)
                            .background(spinning ? AppColors.onSurfaceVariant : AppColors.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(spinning)
                    .accessibilityIdentifier("spin.button")
                }
            }
            .padding(AppSpacing.xl)
        }
    }

    private var wheel: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            for i in 0..<SpinStore.segments.count {
                let start = Angle.degrees(-90 + Double(i) * 45)
                let end = Angle.degrees(-90 + Double(i + 1) * 45)
                var path = Path()
                path.move(to: c)
                path.addArc(center: c, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                path.closeSubpath()
                ctx.fill(path, with: .color(colors[i % colors.count]))
                ctx.stroke(path, with: .color(AppColors.background.opacity(0.6)), lineWidth: 1.5)

                let mid = (-90 + Double(i) * 45 + 22.5) * .pi / 180
                let lr = radius * 0.64
                let pt = CGPoint(x: c.x + cos(mid) * lr, y: c.y + sin(mid) * lr)
                let text = ctx.resolve(
                    Text(label(i)).font(.system(size: radius * 0.12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.onSurface)
                )
                ctx.draw(text, at: pt)
            }
            ctx.fill(
                Path(ellipseIn: CGRect(x: c.x - radius * 0.13, y: c.y - radius * 0.13, width: radius * 0.26, height: radius * 0.26)),
                with: .color(AppColors.surfaceContainerLowest)
            )
        }
    }

    private func spin() {
        guard !spinning, SpinStore.shared.canSpin else { return }
        spinning = true
        let index = SpinStore.shared.chooseIndex()
        let target = 360.0 * 6 - (Double(index) * 45 + 22.5)
        HapticService.shared.impact(.rigid)

        let finish: () -> Void = {
            SpinStore.shared.commit(index: index)
            HapticService.shared.notify(.success)
            SoundService.shared.play(.reward)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                wonIndex = index
                showCelebration = true
            }
        }

        if reduceMotion {
            rotation = target
            finish()
            return
        }
        withAnimation(.timingCurve(0.15, 0.85, 0.2, 1.0, duration: 3.3)) {
            rotation = target
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(3350))
            finish()
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
