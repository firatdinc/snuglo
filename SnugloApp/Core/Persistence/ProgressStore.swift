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

    /// How many daily puzzle levels are offered each day (increasing difficulty).
    static let dailyLevelCount = 5

    // MARK: - Domain Models

    struct LevelProgress: Codable, Hashable {
        var isCompleted: Bool
        var stars: Int          // 0..3
        var bestTime: TimeInterval?
        var completedAt: Date?
        var bestHintsUsed: Int?
    }

    struct DailyPuzzleResult: Codable, Hashable {
        var date: String        // "yyyy-MM-dd"
        var solved: Bool
        var time: TimeInterval?
    }

    /// Today's multi-level daily challenge progress. `solvedCount` is how many
    /// of the day's levels have been solved in order (also = index of the next
    /// playable level). Resets automatically when the date rolls over.
    struct DailyChallengeState: Codable, Hashable {
        var date: String        // "yyyy-MM-dd"
        var solvedCount: Int    // 0 … dailyLevelCount
    }

    // MARK: - Observed Properties

    private(set) var levelProgress: [String: LevelProgress] = [:]
    private(set) var dailyResults: [DailyPuzzleResult] = []
    private(set) var dailyChallenge: DailyChallengeState?
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    /// Play streak — consecutive days the player completed ANY level (campaign or
    /// daily). Surfaced on the main menu. Distinct from `currentStreak`, which only
    /// counts daily-puzzle days (kept for Game Center).
    private(set) var playStreak: Int = 0
    private(set) var longestPlayStreak: Int = 0
    /// Day keys ("yyyy-MM-dd") on which the player completed at least one level.
    private(set) var playedDays: Set<String> = []

    /// Win-streak chain — consecutive level solves WITHOUT a fail/quit between
    /// them. Drives the "don't break the chain" loss-aversion loop. Session-scoped
    /// (in-memory): resets on app launch, fail, or quit. Not persisted.
    private(set) var winChain: Int = 0
    private(set) var bestWinChain: Int = 0

    /// Highest play-streak milestone already rewarded (persisted) + the freshly
    /// crossed milestone awaiting its celebration/reward (transient).
    private(set) var lastRewardedStreak: Int = 0
    private(set) var pendingStreakMilestone: Int?
    static let streakMilestones = [3, 7, 14, 30, 60, 100]

    /// Held streak freezes — each auto-protects a single missed day (Duolingo-style).
    private(set) var streakFreezes: Int = 0
    static let freezeCostGems = 5
    /// Kalan hint sayısı. Consumable IAP (com.snuglo.hints.small) satın alındığında +10.
    /// Faz G-1: persist edilir; GameView'da hint kullanımı Faz H'de hook'lanır.
    private(set) var hintCount: Int = 0
    private(set) var lastClaimedDate: Date?
    private(set) var lastClaimedDay: Int = 0

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

    /// Mark a level as solved. Keeps best stars + best time + best (lowest) hints used.
    func markCompleted(levelId: String, stars: Int, time: TimeInterval, hintsUsed: Int = 0) {
        var prog = levelProgress[levelId]
            ?? LevelProgress(isCompleted: false, stars: 0, bestTime: nil, completedAt: nil)
        prog.isCompleted = true
        prog.stars = max(prog.stars, stars)
        if prog.bestTime == nil || time < prog.bestTime! { prog.bestTime = time }
        if prog.bestHintsUsed == nil || hintsUsed < prog.bestHintsUsed! { prog.bestHintsUsed = hintsUsed }
        prog.completedAt = Date()
        levelProgress[levelId] = prog
        recordPlayDay()
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
        recordPlayDay(date)
        save()
    }

    /// How many of TODAY's daily levels are solved (0 if it's a new day).
    func dailySolvedCount(date: Date = Date()) -> Int {
        let key = ProgressStore.dayKey(date)
        if let dc = dailyChallenge, dc.date == key { return dc.solvedCount }
        return 0
    }

    /// True once all of today's daily levels are solved → card locks until tomorrow.
    func isDailyAllComplete(date: Date = Date()) -> Bool {
        dailySolvedCount(date: date) >= ProgressStore.dailyLevelCount
    }

    /// Records a solved daily level. Levels are sequential, so `solvedCount`
    /// only advances when `index` is the current frontier. Also updates the
    /// streak (a day counts as "played" once its first level is solved).
    func markDailyLevelSolved(index: Int, date: Date = Date(), time: TimeInterval) {
        let key = ProgressStore.dayKey(date)
        if dailyChallenge?.date != key {
            dailyChallenge = DailyChallengeState(date: key, solvedCount: 0)
        }
        if index + 1 > (dailyChallenge?.solvedCount ?? 0) {
            dailyChallenge?.solvedCount = min(index + 1, ProgressStore.dailyLevelCount)
        }
        markDailySolved(date: date, time: time)   // streak + dailyResults + save
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
    /// Excludes the daily puzzle ("daily-…") — the daily is tracked separately
    /// (dailyResults / streak) and must NOT inflate the campaign "/240" counters.
    func totalLevelsCompleted() -> Int {
        levelProgress.filter { $0.key.hasPrefix("daily") == false && $0.value.isCompleted }.count
    }

    /// Average best-time across all completed levels. Returns 0 if none.
    func averageTime() -> TimeInterval {
        let times = levelProgress.values.compactMap(\.bestTime)
        return times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
    }

    // MARK: - Lifetime aggregates (campaign only — excludes daily)

    private var campaignProgress: [LevelProgress] {
        levelProgress.filter { !$0.key.hasPrefix("daily") && $0.value.isCompleted }.map(\.value)
    }

    /// Total stars earned across all completed campaign levels (0…3 each).
    func totalStarsEarned() -> Int {
        campaignProgress.reduce(0) { $0 + $1.stars }
    }

    /// Number of campaign levels solved with a perfect 3-star rating.
    func perfectSolves() -> Int {
        campaignProgress.filter { $0.stars >= 3 }.count
    }

    /// Fastest single solve across all completed campaign levels.
    func bestSolveTime() -> TimeInterval? {
        campaignProgress.compactMap(\.bestTime).min()
    }

    /// Distinct days the player has completed at least one level.
    func daysPlayed() -> Int { playedDays.count }

    /// Total stars earned within a single pack (sum of per-level best stars).
    func packStarsEarned(_ packId: String) -> Int {
        levelProgress
            .filter { $0.key.hasPrefix("\(packId)-") && $0.value.isCompleted }
            .reduce(0) { $0 + $1.value.stars }
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

    /// Records that the player completed a level today, then refreshes the play streak.
    private func recordPlayDay(_ date: Date = Date()) {
        playedDays.insert(ProgressStore.dayKey(date))
        updatePlayStreak()
        checkStreakMilestone()   // caller save()s after; persists lastRewardedStreak
    }

    // MARK: - Streak milestones

    private func highestMilestone(notExceeding n: Int) -> Int {
        ProgressStore.streakMilestones.last { $0 <= n } ?? 0
    }

    /// Flags a milestone the first time the play streak reaches it.
    private func checkStreakMilestone() {
        let m = highestMilestone(notExceeding: playStreak)
        if m > lastRewardedStreak {
            pendingStreakMilestone = m
            lastRewardedStreak = m
        }
    }

    /// Reward for reaching a streak milestone (coins, gems).
    static func streakReward(forMilestone m: Int) -> (coins: Int, gems: Int) {
        m >= 30 ? (m * 10, max(1, m / 30)) : (m * 10, 0)
    }

    /// Returns and clears the pending milestone (the UI grants its reward).
    func consumeStreakMilestone() -> Int? {
        let m = pendingStreakMilestone
        pendingStreakMilestone = nil
        return m
    }

    // MARK: - Streak freeze

    /// Buy a streak freeze with gems. Returns true on success.
    @MainActor
    @discardableResult
    func buyStreakFreeze(wallet: WalletStore = .shared) -> Bool {
        guard wallet.spend(.gem, amount: ProgressStore.freezeCostGems) else { return false }
        streakFreezes += 1
        save()
        return true
    }

    /// If exactly YESTERDAY was missed (and the day before was played) and a freeze
    /// is held, spend it to bridge the gap so the play streak survives. Idempotent —
    /// once bridged, yesterday is in `playedDays` so it can't re-trigger.
    private func applyFreezeBridge() {
        guard streakFreezes > 0 else { return }
        let cal = Calendar.current
        let df = makeDayFormatter()
        let today = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
              let dayBefore = cal.date(byAdding: .day, value: -2, to: today) else { return }
        let yKey = df.string(from: yesterday)
        // Bridge only a SINGLE missed day (yesterday) following an active streak.
        if !playedDays.contains(yKey), playedDays.contains(df.string(from: dayBefore)) {
            playedDays.insert(yKey)
            streakFreezes -= 1
            save()
        }
    }

    /// Recalculates `playStreak` — consecutive days (ending today, or yesterday if
    /// today hasn't been played yet) present in `playedDays`. Same shape as
    /// `updateStreak`, but over the any-level "played" set rather than daily solves.
    private func updatePlayStreak() {
        applyFreezeBridge()   // spend a held freeze to bridge a single missed day
        let cal = Calendar.current
        let df = makeDayFormatter()

        var start = cal.startOfDay(for: Date())
        if !playedDays.contains(df.string(from: start)) {
            start = cal.date(byAdding: .day, value: -1, to: start) ?? start
        }

        var streak = 0
        var checkDate = start
        while playedDays.contains(df.string(from: checkDate)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        playStreak = streak
        longestPlayStreak = max(longestPlayStreak, streak)
    }

    /// Recalculates the play streak (call when returning to the foreground, to
    /// catch breaks that happened while backgrounded). Mirrors `refreshStreak`.
    func refreshPlayStreak() {
        updatePlayStreak()
    }

    // MARK: - Win-streak chain (session)

    /// Records a level solve; grows the chain. Returns the NEW chain length.
    @discardableResult
    func recordWin() -> Int {
        winChain += 1
        bestWinChain = max(bestWinChain, winChain)
        return winChain
    }

    /// Breaks the chain (level failed or quit mid-play).
    func breakChain() {
        winChain = 0
    }

    /// Escalating coin bonus for keeping the chain alive (chain ≥ 2). Caps so it
    /// stays a flavour bonus, not a balance-breaker. Chain 2→+10, 3→+20 … cap +80.
    static func chainCoinBonus(forChain chain: Int) -> Int {
        guard chain >= 2 else { return 0 }
        // Tightened (was (chain-1)*10, cap 80) to slow soft-currency farming.
        return min(40, (chain - 1) * 5)
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var levelProgress: [String: LevelProgress]
        var dailyResults: [DailyPuzzleResult]
        var currentStreak: Int
        var longestStreak: Int
        /// hintCount Faz G-1'de eklendi; eski snapshot'larda yoksa 0 kullan.
        var hintCount: Int
        /// lastClaimedDate / lastClaimedDay Faz 6'da eklendi; eski snapshot'larda yoksa nil/0.
        var lastClaimedDate: Date?
        var lastClaimedDay: Int
        /// dailyChallenge v1.2'de eklendi (çok-bölümlü günlük); eski snapshot'larda yoksa nil.
        var dailyChallenge: DailyChallengeState?
        /// playedDays / longestPlayStreak play-streak feature'ında eklendi; eski
        /// snapshot'larda yoksa boş → load() geçmiş veriden backfill eder.
        var playedDays: [String]
        var longestPlayStreak: Int
        /// lastRewardedStreak added with streak-milestone rewards; absent → 0.
        var lastRewardedStreak: Int
        /// streakFreezes added with the streak-freeze feature; absent → 0.
        var streakFreezes: Int

        // Explicit memberwise init (custom init(from:) suppresses synthesis).
        init(levelProgress: [String: LevelProgress], dailyResults: [DailyPuzzleResult],
             currentStreak: Int, longestStreak: Int, hintCount: Int,
             lastClaimedDate: Date?, lastClaimedDay: Int,
             dailyChallenge: DailyChallengeState?,
             playedDays: [String], longestPlayStreak: Int, lastRewardedStreak: Int,
             streakFreezes: Int) {
            self.streakFreezes = streakFreezes
            self.levelProgress      = levelProgress
            self.dailyResults       = dailyResults
            self.currentStreak      = currentStreak
            self.longestStreak      = longestStreak
            self.hintCount          = hintCount
            self.lastClaimedDate    = lastClaimedDate
            self.lastClaimedDay     = lastClaimedDay
            self.dailyChallenge     = dailyChallenge
            self.playedDays         = playedDays
            self.longestPlayStreak  = longestPlayStreak
            self.lastRewardedStreak = lastRewardedStreak
        }

        // Custom decoder: hintCount added Faz G-1; lastClaimedDate/Day added Faz 6;
        // dailyChallenge added v1.2; playedDays/longestPlayStreak added with the
        // play-streak feature. All absent in older builds → use defaults.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            levelProgress    = try container.decode([String: LevelProgress].self, forKey: .levelProgress)
            dailyResults     = try container.decode([DailyPuzzleResult].self, forKey: .dailyResults)
            currentStreak    = try container.decode(Int.self, forKey: .currentStreak)
            longestStreak    = try container.decode(Int.self, forKey: .longestStreak)
            hintCount        = try container.decodeIfPresent(Int.self, forKey: .hintCount) ?? 0
            lastClaimedDate  = try container.decodeIfPresent(Date.self, forKey: .lastClaimedDate)
            lastClaimedDay   = try container.decodeIfPresent(Int.self, forKey: .lastClaimedDay) ?? 0
            dailyChallenge   = try container.decodeIfPresent(DailyChallengeState.self, forKey: .dailyChallenge)
            playedDays       = try container.decodeIfPresent([String].self, forKey: .playedDays) ?? []
            longestPlayStreak = try container.decodeIfPresent(Int.self, forKey: .longestPlayStreak) ?? 0
            lastRewardedStreak = try container.decodeIfPresent(Int.self, forKey: .lastRewardedStreak) ?? 0
            streakFreezes = try container.decodeIfPresent(Int.self, forKey: .streakFreezes) ?? 0
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        levelProgress   = snap.levelProgress
        dailyResults    = snap.dailyResults
        dailyChallenge  = snap.dailyChallenge
        hintCount       = snap.hintCount
        lastClaimedDate = snap.lastClaimedDate
        lastClaimedDay  = snap.lastClaimedDay
        // Restore longestStreak from disk; currentStreak is always recalculated
        // so stale/ghost streaks (e.g. user missed a day) are corrected on every launch.
        longestStreak = snap.longestStreak

        // Play streak: restore, then backfill from existing history so day-1 of the
        // feature doesn't wipe streaks earned before it shipped. Idempotent.
        playedDays = Set(snap.playedDays)
        longestPlayStreak = snap.longestPlayStreak
        streakFreezes = snap.streakFreezes
        var derived = Set(dailyResults.filter(\.solved).map(\.date))
        for prog in levelProgress.values where prog.isCompleted {
            if let c = prog.completedAt { derived.insert(ProgressStore.dayKey(c)) }
        }
        playedDays.formUnion(derived)

        updateStreak()
        updatePlayStreak()

        // Streak milestones: silently catch up so pre-existing streaks don't pop a
        // reward on launch; only live crossings during play trigger the celebration.
        lastRewardedStreak = max(snap.lastRewardedStreak, highestMilestone(notExceeding: playStreak))
        pendingStreakMilestone = nil
    }

    private func save() {
        let snap = Snapshot(
            levelProgress: levelProgress,
            dailyResults: dailyResults,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hintCount: hintCount,
            lastClaimedDate: lastClaimedDate,
            lastClaimedDay: lastClaimedDay,
            dailyChallenge: dailyChallenge,
            playedDays: Array(playedDays),
            longestPlayStreak: longestPlayStreak,
            lastRewardedStreak: lastRewardedStreak,
            streakFreezes: streakFreezes
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
        levelProgress     = [:]
        dailyResults      = []
        dailyChallenge    = nil
        currentStreak     = 0
        longestStreak     = 0
        playStreak        = 0
        longestPlayStreak = 0
        playedDays        = []
        lastRewardedStreak = 0
        pendingStreakMilestone = nil
        streakFreezes = 0
        hintCount         = 0
        lastClaimedDate   = nil
        lastClaimedDay    = 0
        save()
    }
}

// MARK: - Daily Reward (Faz 6)

extension ProgressStore {
    var canClaimDailyReward: Bool {
        guard let last = lastClaimedDate else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    /// Claims today's daily reward. Returns nil if already claimed today.
    /// Gap > 1 calendar day resets the 7-day cycle to day 1.
    @MainActor
    @discardableResult
    func claimDailyReward(now: Date = .now, isPremium: Bool, wallet: WalletStore = .shared) -> [Currency: Int]? {
        guard canClaimDailyReward else { return nil }
        let cal = Calendar.current
        if let last = lastClaimedDate {
            let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))
            if cal.startOfDay(for: last) != yesterday { lastClaimedDay = 0 }
        }
        let nextDay = (lastClaimedDay % 7) + 1
        let reward = DailyRewardCalculator.reward(forDay: nextDay, isPremium: isPremium)
        for (currency, amount) in reward {
            wallet.earn(currency, amount: amount)
        }
        lastClaimedDate = now
        lastClaimedDay  = nextDay
        save()
        return reward
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
