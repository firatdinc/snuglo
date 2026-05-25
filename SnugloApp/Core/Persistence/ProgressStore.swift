import Foundation
import Observation

// MARK: — ProgressStore
// Single source of truth for player progress.
// Backed by UserDefaults (JSON-encoded snapshots).
// Thread model: all mutation expected on the main actor (GameViewModel + SwiftUI).
// Faz E — Persistence layer.

@Observable
final class ProgressStore {

    // MARK: - Singleton

    static let shared = ProgressStore()

    // MARK: - Domain Models

    struct LevelProgress: Codable, Hashable {
        var isCompleted: Bool
        var stars: Int          // 0..3
        var bestTime: TimeInterval?
        var completedAt: Date?
    }

    struct DailyPuzzleResult: Codable, Hashable {
        var date: String        // "yyyy-MM-dd"
        var solved: Bool
        var time: TimeInterval?
    }

    // MARK: - Observed Properties

    private(set) var levelProgress: [String: LevelProgress] = [:]
    private(set) var dailyResults: [DailyPuzzleResult] = []
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    /// Kalan hint sayısı. Consumable IAP (com.snuglo.hints.small) satın alındığında +10.
    /// Faz G-1: persist edilir; GameView'da hint kullanımı Faz H'de hook'lanır.
    private(set) var hintCount: Int = 0

    // MARK: - Private

    private let defaults: UserDefaults
    private let key: String

    // MARK: - Init

    /// Shared instance — uses standard UserDefaults.
    init(defaults: UserDefaults = .standard, key: String = "snuglo.progress.v1") {
        self.defaults = defaults
        self.key = key
        load()
    }

    // MARK: - Public API

    /// Mark a level as solved. Keeps best stars + best time.
    func markCompleted(levelId: String, stars: Int, time: TimeInterval) {
        var prog = levelProgress[levelId]
            ?? LevelProgress(isCompleted: false, stars: 0, bestTime: nil, completedAt: nil)
        prog.isCompleted = true
        prog.stars = max(prog.stars, stars)
        if prog.bestTime == nil || time < prog.bestTime! { prog.bestTime = time }
        prog.completedAt = Date()
        levelProgress[levelId] = prog
        save()
    }

    /// Mark today's daily puzzle as solved.
    func markDailySolved(date: Date, time: TimeInterval) {
        let dayKey = ProgressStore.dayKey(date)
        if let i = dailyResults.firstIndex(where: { $0.date == dayKey }) {
            dailyResults[i].solved = true
            if dailyResults[i].time == nil || time < (dailyResults[i].time ?? .infinity) {
                dailyResults[i].time = time
            }
        } else {
            dailyResults.append(DailyPuzzleResult(date: dayKey, solved: true, time: time))
        }
        updateStreak()
        save()
    }

    /// Recalculates currentStreak from stored dailyResults.
    /// Call from StatsView.onAppear to catch streak breaks that occurred while
    /// the app was backgrounded (e.g. user returns after missing a day).
    func refreshStreak() {
        updateStreak()
    }

    // MARK: - Query Helpers

    func isLevelCompleted(_ levelId: String) -> Bool {
        levelProgress[levelId]?.isCompleted ?? false
    }

    /// Level 1 of every pack is always unlocked. Level N unlocks when N-1 is completed.
    func isLevelUnlocked(packId: String, levelIndex: Int) -> Bool {
        if levelIndex == 1 { return true }
        return isLevelCompleted("\(packId)-\(levelIndex - 1)")
    }

    /// How many levels in a given pack are completed.
    func packCompletionCount(_ packId: String) -> Int {
        levelProgress.keys.filter {
            $0.hasPrefix("\(packId)-") && (levelProgress[$0]?.isCompleted == true)
        }.count
    }

    /// Total completed levels across all packs.
    func totalLevelsCompleted() -> Int {
        levelProgress.values.filter(\.isCompleted).count
    }

    /// Average best-time across all completed levels. Returns 0 if none.
    func averageTime() -> TimeInterval {
        let times = levelProgress.values.compactMap(\.bestTime)
        return times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
    }

    // MARK: - Streak Calculation

    private func updateStreak() {
        let cal = Calendar.current
        let df = makeDayFormatter()
        let solvedSet = Set(dailyResults.filter(\.solved).map(\.date))

        var streakStart = cal.startOfDay(for: Date())
        // If today isn't solved yet, the active streak may still be from yesterday
        if !solvedSet.contains(df.string(from: streakStart)) {
            streakStart = cal.date(byAdding: .day, value: -1, to: streakStart) ?? streakStart
        }

        var streak = 0
        var checkDate = streakStart
        while solvedSet.contains(df.string(from: checkDate)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        currentStreak = streak
        longestStreak = max(longestStreak, streak)
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var levelProgress: [String: LevelProgress]
        var dailyResults: [DailyPuzzleResult]
        var currentStreak: Int
        var longestStreak: Int
        /// hintCount Faz G-1'de eklendi; eski snapshot'larda yoksa 0 kullan.
        var hintCount: Int = 0
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        levelProgress = snap.levelProgress
        dailyResults  = snap.dailyResults
        hintCount     = snap.hintCount
        // Restore longestStreak from disk; currentStreak is always recalculated
        // so stale/ghost streaks (e.g. user missed a day) are corrected on every launch.
        longestStreak = snap.longestStreak
        updateStreak()
    }

    private func save() {
        let snap = Snapshot(
            levelProgress: levelProgress,
            dailyResults: dailyResults,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hintCount: hintCount
        )
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Helpers

    static func dayKey(_ d: Date = Date()) -> String {
        makeDayFormatter().string(from: d)
    }

    private static func makeDayFormatter() -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }

    private func makeDayFormatter() -> DateFormatter { ProgressStore.makeDayFormatter() }

    // MARK: - Hints (Faz G-1)

    /// Consumable IAP satın alımı sonrası çağrılır (StoreManager tarafından).
    func addHints(_ count: Int) {
        hintCount += count
        save()
    }

    /// Hint kullanımı — Faz H'de GameView'da hook'lanır.
    /// false döndürürse hint yoktur.
    @discardableResult
    func useHint() -> Bool {
        guard hintCount > 0 else { return false }
        hintCount -= 1
        save()
        return true
    }

    // MARK: - Reset (test / settings)

    func reset() {
        levelProgress = [:]
        dailyResults  = []
        currentStreak = 0
        longestStreak = 0
        hintCount     = 0
        save()
    }
}

// MARK: - Formatted helpers (UI convenience)

extension ProgressStore {
    /// "2:34" format from average time interval.
    var averageTimeFormatted: String {
        let t = averageTime()
        guard t > 0 else { return "—" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Results for the last N days (today = index N-1).
    func recentDailyResults(days: Int = 7) -> [(label: String, solved: Bool, isToday: Bool)] {
        let cal = Calendar.current
        let df  = makeDayFormatter()
        let labelDF = DateFormatter()
        labelDF.dateFormat = "E"  // "Mon", "Tue" …
        labelDF.locale = Locale(identifier: "en_US_POSIX")

        let solvedSet = Set(dailyResults.filter(\.solved).map(\.date))
        let today = cal.startOfDay(for: Date())

        return (0..<days).reversed().map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let key  = df.string(from: date)
            let lbl  = String(labelDF.string(from: date).prefix(1))
            return (label: lbl, solved: solvedSet.contains(key), isToday: daysAgo == 0)
        }
    }
}
