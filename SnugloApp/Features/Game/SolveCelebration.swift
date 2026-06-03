import SwiftUI

// MARK: — SolveCelebration
// A short, self-contained confetti burst shown when a level is solved.
// Pure SwiftUI (TimelineView + Canvas), no dependencies. Colours come strictly
// from AppColors tokens. Caller mounts it for ~1.8s then removes it; it ignores
// hit-testing and is skipped entirely under Reduce Motion (caller's choice).

struct SolveCelebration: View {
    var duration: Double = 1.8
    /// 0…1 — scales particle count & energy (longer win-streaks burst harder).
    var intensity: Double = 0.5

    @State private var start = Date()

    private struct Particle {
        let color: Color
        let angle: Double      // emission angle (radians)
        let speed: Double      // initial speed
        let size: CGFloat
        let spin: Double       // rotations over lifetime
        let delay: Double
        let wobble: Double
    }

    private let particles: [Particle]

    init(duration: Double = 1.8, intensity: Double = 0.5) {
        self.duration = duration
        self.intensity = intensity
        let palette: [Color] = [
            AppColors.tertiary, AppColors.primary, AppColors.secondary,
            AppColors.blockLavender, AppColors.blockPeach, AppColors.blockSage,
        ]
        let count = Int(40 + max(0, min(1, intensity)) * 50)
        particles = (0..<count).map { i in
            // Golden-ratio spread for an even, organic fan; small per-index variety.
            let r = (Double(i) * 0.61803398875).truncatingRemainder(dividingBy: 1)
            let r2 = (Double(i) * 0.75487766624).truncatingRemainder(dividingBy: 1)
            // Emit upward-and-outward: angles fan across the top hemisphere.
            let angle = (-Double.pi / 2) + (r - 0.5) * (Double.pi * 1.1)
            return Particle(
                color: palette[i % palette.count],
                angle: angle,
                speed: 520 + r2 * 540,
                size: 6 + CGFloat(r2) * 8,
                spin: 1 + r * 3,
                delay: r2 * 0.12,
                wobble: (r - 0.5) * 90
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                guard t < duration else { return }
                let cx = size.width / 2
                let cy = size.height * 0.34
                let gravity = 1500.0
                for p in particles {
                    let lt = t - p.delay
                    guard lt > 0 else { continue }
                    let progress = min(1, lt / (duration - p.delay))
                    let vx = cos(p.angle) * p.speed
                    let vy = sin(p.angle) * p.speed
                    let x = cx + vx * lt + sin(lt * 6 + p.delay * 10) * p.wobble
                    let y = cy + vy * lt + 0.5 * gravity * lt * lt
                    let alpha = progress < 0.7 ? 1.0 : max(0, 1 - (progress - 0.7) / 0.3)

                    var inner = ctx
                    inner.translateBy(x: x, y: y)
                    inner.rotate(by: .radians(p.spin * lt * 2 * .pi))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size * 0.6)
                    inner.opacity = alpha
                    inner.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
