import Foundation
import Observation

// MARK: — EndlessStore
// Tracks the best Endless-Zen run (highest level index reached). Self-contained:
// own UserDefaults key.

@Observable
final class EndlessStore {

    static let shared = EndlessStore()

    private(set) var best: Int

    private let defaults: UserDefaults
    private let key = "snuglo.endless.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = defaults.integer(forKey: key)
    }

    /// Records reaching/clearing endless level `index`; keeps the best run.
    /// Returns true when this set a NEW personal best (for celebration).
    @discardableResult
    func record(index: Int) -> Bool {
        guard index > best else { return false }
        best = index
        defaults.set(best, forKey: key)
        return true
    }
}
