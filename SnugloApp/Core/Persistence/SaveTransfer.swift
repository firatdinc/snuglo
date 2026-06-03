import Foundation

// MARK: — SaveTransfer
// Backup / restore the full local save as a single portable code (base64 of a
// binary property list). Self-contained — no network, no account. The user can
// copy/share the code and paste it on another device to migrate progress.
//
// Faithfully preserves every value type (Int/Double/Bool/String/Data/arrays)
// via PropertyListSerialization, so each store's encoded snapshot survives
// round-trips intact. Stores read these keys at launch, so a restore takes
// effect after the next app start.

enum SaveTransfer {

    /// All persistence keys that make up a player's save (progress, economy,
    /// cosmetics, meta-progress + preferences). System/test keys are excluded.
    static let keys: [String] = [
        // Core progress & economy
        "snuglo.progress.v1",
        "snuglo.wallet.v1",
        "snuglo.xp.v1",
        // Meta-progress stores
        "snuglo.chests.v1",
        "snuglo.spin.v1",
        "snuglo.dailyquests.v1",
        "snuglo.weekly.v1",
        "snuglo.cosmetics.v1",
        "snuglo.dailycal.v1",
        "snuglo.endless.v1",
        "snuglo.packrewards.v1", "snuglo.packrewards.pending",
        // Preferences
        "blockSkin", "boardBackground", "soundPack",
        "musicEnabled", "musicVolume", "musicTrack",
        "sfxEnabled", "sfxVolume",
        "hapticsEnabled", "hapticLevel",
        "zenMode", "colorblindMode", "appTheme",
        "dailyReminderEnabled", "dailyReminderTime",
        "snuglo.dailyReminder.enabled",
        "comebackRemindersEnabled", "coachShown", "hasOnboarded",
        "snuglo.ads.consent", "snuglo.language.override",
    ]

    private static let header = "snuglo"
    private static let version = 1

    /// Encode the current save into a portable code string. Nil only on the
    /// (practically impossible) serialization failure.
    static func export(_ defaults: UserDefaults = .standard) -> String? {
        var data: [String: Any] = [:]
        for key in keys {
            if let value = defaults.object(forKey: key) { data[key] = value }
        }
        let payload: [String: Any] = ["app": header, "v": version, "data": data]
        guard let plist = try? PropertyListSerialization.data(
            fromPropertyList: payload, format: .binary, options: 0
        ) else { return nil }
        return plist.base64EncodedString()
    }

    enum ImportResult: Equatable { case success(Int), invalid }

    /// Restore a save from a previously-exported code. Validates the header
    /// before writing anything. Returns the number of keys restored.
    @discardableResult
    static func importCode(_ code: String, into defaults: UserDefaults = .standard) -> ImportResult {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = Data(base64Encoded: trimmed),
              let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let payload = obj as? [String: Any],
              payload["app"] as? String == header,
              let dict = payload["data"] as? [String: Any] else {
            return .invalid
        }
        for (key, value) in dict where keys.contains(key) {
            defaults.set(value, forKey: key)
        }
        return .success(dict.count)
    }
}
