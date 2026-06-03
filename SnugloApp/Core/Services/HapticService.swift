import UIKit

// MARK: — HapticService (Faz F)
//
// Thin wrapper around UIKit haptic generators.
// Generators are lazy — created on first use to avoid allocating when unused.
// Call prepareImpact() at drag-start for sub-millisecond latency on impact.
// Gate: UserDefaults("hapticsEnabled") checked on every call; false → no-op.

@MainActor
final class HapticService {

    // MARK: — Singleton
    static let shared = HapticService()

    // MARK: — Generators (lazy for performance)
    private lazy var lightGenerator  = UIImpactFeedbackGenerator(style: .light)
    private lazy var mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var rigidGenerator  = UIImpactFeedbackGenerator(style: .rigid)
    private lazy var notifyGenerator = UINotificationFeedbackGenerator()
    private lazy var selectionGenerator = UISelectionFeedbackGenerator()

    private init() {}

    // MARK: — Public API

    /// Call when drag begins so UIKit pre-warms the taptic engine.
    /// No-op when hapticsEnabled is false.
    func prepareImpact() {
        guard isEnabled else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
    }

    /// Trigger an impact vibration.
    /// - `.light` — piece lands on tray / successful small place.
    /// - `.medium` — piece snaps to grid cell.
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        // "Light" strength softens every impact to a gentle tap.
        if hapticLevel == "light" {
            lightGenerator.impactOccurred()
            return
        }
        switch style {
        case .light:
            lightGenerator.impactOccurred()
        case .medium:
            mediumGenerator.impactOccurred()
        case .rigid:
            rigidGenerator.impactOccurred()
        default:
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    /// A light "tick" as the dragged piece hovers from one grid cell to the next.
    /// Skipped on "Light" strength — these per-cell ticks are the buzziest layer.
    func selection() {
        guard isEnabled, hapticLevel != "light" else { return }
        selectionGenerator.selectionChanged()
    }

    /// Trigger a notification vibration pattern.
    /// - `.success` — puzzle solved.
    /// - `.error`   — invalid placement.
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notifyGenerator.notificationOccurred(type)
    }

    // MARK: — Private helpers

    private var isEnabled: Bool {
        // Default true if key never set.
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    /// "full" (default) or "light" — user-controlled haptic strength.
    private var hapticLevel: String {
        UserDefaults.standard.string(forKey: "hapticLevel") ?? "full"
    }
}
