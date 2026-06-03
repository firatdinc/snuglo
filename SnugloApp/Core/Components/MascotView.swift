import SwiftUI

// MARK: — MascotView
// A mascot image with life: a gentle idle "breathing" bob, plus an optional
// one-shot happy reaction (hop + wiggle) when `celebrate` is true — e.g. on a
// level solve. Static PNGs are animated purely via transforms, so it stays
// crisp and self-contained. Reduce-Motion safe (renders perfectly still).

struct MascotView: View {
    let name: String
    var size: CGFloat = 96
    /// Play a happy hop + wiggle once on appear (use for solve/reward moments).
    var celebrate: Bool = false
    /// Clip the image to a circle (matches the hero ring style).
    var clipCircle: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false
    @State private var pop: CGFloat = 1
    @State private var tilt: Double = 0

    var body: some View {
        image
            .scaleEffect(pop * (bob ? 1.03 : 1.0), anchor: .bottom)
            .rotationEffect(.degrees(tilt), anchor: .bottom)
            .offset(y: bob ? -3 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    bob = true
                }
                if celebrate { runCelebrate() }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var image: some View {
        let base = Image(name).resizable().scaledToFit().frame(width: size, height: size)
        if clipCircle { base.clipShape(Circle()) } else { base }
    }

    /// A quick joyful hop and a couple of cheeky wiggles, then settle.
    private func runCelebrate() {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.4)) { pop = 1.18 }
        withAnimation(.easeInOut(duration: 0.12).repeatCount(4, autoreverses: true)) { tilt = 6 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.6)) { pop = 1 }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.15)) { tilt = 0 }
        }
    }
}
