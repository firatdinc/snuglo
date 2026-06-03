import SwiftUI

// MARK: — AppMotion
// Shared motion tokens so every animation across the app shares one rhythm.
// In Zen Mode the whole rhythm slows and softens (longer response, higher
// damping = no overshoot) for a calmer, meditative feel. Tokens are computed;
// RootView rebuilds on the zenMode toggle so callers re-read them.
enum AppMotion {
    /// True when Zen Mode is on (read live).
    private static var zen: Bool { UserDefaults.standard.bool(forKey: "zenMode") }

    /// Cards / surfaces settling into place.
    static var card: Animation {
        zen ? .spring(response: 0.58, dampingFraction: 0.92)
            : .spring(response: 0.38, dampingFraction: 0.84)
    }
    /// Snappy pops (badges, rewards) — gentled in Zen.
    static var pop: Animation {
        zen ? .spring(response: 0.46, dampingFraction: 0.84)
            : .spring(response: 0.3, dampingFraction: 0.6)
    }

    /// Per-item stagger delay — a slower, calmer cascade in Zen.
    static var staggerStep: Double { zen ? 0.08 : 0.05 }
}

// MARK: — AppearStagger
// A subtle staggered entrance (fade + rise) for lists/grids of cards. Reduce-Motion
// safe (appears instantly). Use `.appearStagger(index)` on each item.
private struct AppearStagger: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .onAppear {
                guard !reduceMotion else { shown = true; return }
                withAnimation(AppMotion.card.delay(Double(index) * AppMotion.staggerStep)) { shown = true }
            }
    }
}

extension View {
    /// Staggered fade-and-rise entrance; `index` sets the per-item delay.
    func appearStagger(_ index: Int) -> some View {
        modifier(AppearStagger(index: index))
    }
}
