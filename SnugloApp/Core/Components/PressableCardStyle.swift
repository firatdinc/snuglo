import SwiftUI

// MARK: — PressableCardStyle
// A consistent press response for tappable cards/buttons: a subtle scale + dim
// with a light haptic on press-down. Respects Reduce Motion (no scale).

struct PressableCardStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                       value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { HapticService.shared.impact(.light) }
            }
    }
}
