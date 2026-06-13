import SwiftUI

// MARK: — EnergySpendBadge
// A one-shot "−5 ⚡" flourish shown when a paid level starts, so the energy cost is
// felt rather than silently deducted. Pops in with a spring, holds, then floats up
// and fades.
//
// Motion rationale (design-motion-principles · mobile app → Jakub-primary polish
// with a Jhey delight beat): this fires at most once per level start — a RARE
// event — so an expressive, noticeable beat is appropriate where a high-frequency
// control would get none. Entrance is a spring pop (scale + fade) reusing the
// app's `AppMotion.pop` rhythm; exit is a softer ease-out drift upward (exit
// subtler than enter). Only `opacity`, `scale`, and `offset` (transforms) animate.
// Reduce Motion collapses it to a plain fade in/out — no scale, no travel — to
// stay vestibular-safe.

struct EnergySpendBadge: View {
    /// Energy points spent (shown as "−amount").
    let amount: Int
    /// Called once the flourish has fully played out so the host can clear it.
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shown = false
    @State private var floatedAway = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 13, weight: .bold))
            Text(verbatim: "−\(amount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.sm + 2)
        .padding(.vertical, AppSpacing.xs + 2)
        .background(AppColors.tertiary, in: Capsule())
        .overlay(
            Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1)
        )
        .shadowL1()
        .opacity(shown && !floatedAway ? 1 : 0)
        .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.6))
        .offset(y: yOffset)
        .accessibilityLabel(Text(verbatim: String(
            format: NSLocalizedString("energy.spent.a11y", comment: "energy spent announcement"),
            amount
        )))
        .task { await play() }
    }

    /// Initial dip → resting → upward drift on exit (skipped under Reduce Motion).
    private var yOffset: CGFloat {
        guard !reduceMotion else { return 0 }
        if floatedAway { return -40 }
        return shown ? 0 : -6
    }

    private func play() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) { shown = true }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeIn(duration: 0.3)) { floatedAway = true }
            try? await Task.sleep(for: .milliseconds(300))
            onFinish()
            return
        }
        withAnimation(AppMotion.pop) { shown = true }
        try? await Task.sleep(for: .milliseconds(550))
        withAnimation(.easeOut(duration: 0.5)) { floatedAway = true }
        try? await Task.sleep(for: .milliseconds(500))
        onFinish()
    }
}
