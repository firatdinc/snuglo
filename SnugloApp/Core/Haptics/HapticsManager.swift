import UIKit
import Observation

// MARK: — HapticsManager
// Faz F: UIKit haptic feedback manager.
//
// All generators are pre-warmed in init() to minimise latency on first call.
// iOS: UIImpactFeedbackGenerator / UINotificationFeedbackGenerator / UISelectionFeedbackGenerator
// Android: Not applicable — iOS-only target.

@Observable
final class HapticsManager {

    // MARK: - Singleton

    static let shared = HapticsManager()

    // MARK: - Feedback Types

    enum Feedback {
        case light       // piece pickup
        case medium      // piece drop (no snap)
        case heavy       // reserved / future
        case success     // level complete
        case warning     // reserved / future
        case error       // invalid placement
        case selection   // piece snap into slot
    }

    // MARK: - State

    var enabled: Bool {
        didSet { defaults.set(enabled, forKey: Keys.haptics) }
    }

    // MARK: - Private

    private let defaults: UserDefaults
    private let lightImpact   = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact  = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact   = UIImpactFeedbackGenerator(style: .heavy)
    private let notification  = UINotificationFeedbackGenerator()
    private let selectionFG   = UISelectionFeedbackGenerator()

    private enum Keys {
        static let haptics = "snuglo.haptics.enabled"
    }

    // MARK: - Init

    private convenience init() {
        self.init(defaults: .standard)
    }

    /// Testable init — accepts isolated UserDefaults suite.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.enabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        // Pre-warm all generators to minimise latency
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
        selectionFG.prepare()
    }

    // MARK: - Play

    /// Trigger haptic feedback. No-op if enabled = false.
    func play(_ feedback: Feedback) {
        guard enabled else { return }
        switch feedback {
        case .light:     lightImpact.impactOccurred()
        case .medium:    mediumImpact.impactOccurred()
        case .heavy:     heavyImpact.impactOccurred()
        case .success:   notification.notificationOccurred(.success)
        case .warning:   notification.notificationOccurred(.warning)
        case .error:     notification.notificationOccurred(.error)
        case .selection: selectionFG.selectionChanged()
        }
    }
}
