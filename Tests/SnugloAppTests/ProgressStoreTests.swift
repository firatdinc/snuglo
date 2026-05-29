import XCTest
@testable import SnugloApp

// MARK: — ProgressStoreTests
// Faz E: ProgressStore persistence + unlock logic tests.
// Each test uses an isolated UserDefaults suite to avoid polluting real data.

@MainActor
final class ProgressStoreTests: XCTestCase {

    // MARK: - Factory

    /// Returns a fresh isolated ProgressStore (separate UserDefaults suite per test).
    private func makeStore() -> ProgressStore {
        let suite = "test.progress.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        return ProgressStore(defaults: ud, key: suite)
    }

    // MARK: - testMarkCompletedPersists

    func testMarkCompletedPersists() throws {
        let store = makeStore()
        XCTAssertFalse(store.isLevelCompleted("cozy-beginnings-1"))

        store.markCompleted(levelId: "cozy-beginnings-1", stars: 3, time: 25.0)

        XCTAssertTrue(store.isLevelCompleted("cozy-beginnings-1"))
        XCTAssertEqual(store.levelProgress["cozy-beginnings-1"]?.stars, 3)
        XCTAssertEqual(store.levelProgress["cozy-beginnings-1"]?.bestTime, 25.0)
    }

    func testMarkCompletedKeepsBestTime() {
        let store = makeStore()
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 2, time: 60.0)
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 1, time: 120.0)

        // Best time should stay 60.0, best stars should stay 2
        XCTAssertEqual(store.levelProgress["cozy-beginnings-1"]?.bestTime, 60.0)
        XCTAssertEqual(store.levelProgress["cozy-beginnings-1"]?.stars, 2)
    }

    func testMarkCompletedUpdatesBetterTime() {
        let store = makeStore()
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 1, time: 120.0)
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 3, time: 20.0)

        // Better time + higher stars should be recorded
        XCTAssertEqual(store.levelProgress["cozy-beginnings-1"]?.bestTime, 20.0)
        XCTAssertEqual(store.levelProgress["cozy-beginnings-1"]?.stars, 3)
    }

    // MARK: - testIsLevelUnlocked

    func testIsLevelUnlocked_firstLevelAlwaysOpen() {
        let store = makeStore()
        XCTAssertTrue(store.isLevelUnlocked(packId: "cozy-beginnings", levelIndex: 1))
    }

    func testIsLevelUnlocked_secondLockedUntilFirstDone() {
        let store = makeStore()
        XCTAssertFalse(store.isLevelUnlocked(packId: "cozy-beginnings", levelIndex: 2))

        store.markCompleted(levelId: "cozy-beginnings-1", stars: 1, time: 60.0)
        XCTAssertTrue(store.isLevelUnlocked(packId: "cozy-beginnings", levelIndex: 2))
    }

    func testIsLevelUnlocked_chainedUnlock() {
        let store = makeStore()
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 1, time: 60.0)
        store.markCompleted(levelId: "cozy-beginnings-2", stars: 2, time: 45.0)

        XCTAssertTrue(store.isLevelUnlocked(packId: "cozy-beginnings", levelIndex: 3))
        XCTAssertFalse(store.isLevelUnlocked(packId: "cozy-beginnings", levelIndex: 4))
    }

    // MARK: - testStreakIncrement

    func testStreakIncrement_firstSolveGivesStreak1() {
        let store = makeStore()
        XCTAssertEqual(store.currentStreak, 0)

        store.markDailySolved(date: Date(), time: 90.0)
        XCTAssertEqual(store.currentStreak, 1)
        XCTAssertEqual(store.longestStreak, 1)
    }

    func testStreakIncrement_sameDayDoesNotDouble() {
        let store = makeStore()
        store.markDailySolved(date: Date(), time: 90.0)
        store.markDailySolved(date: Date(), time: 45.0)  // re-solve same day

        XCTAssertEqual(store.currentStreak, 1)
        // Best time should be 45
        let key = ProgressStore.dayKey(Date())
        XCTAssertEqual(store.dailyResults.first(where: { $0.date == key })?.time, 45.0)
    }

    func testStreakIncrement_consecutiveDays() {
        let store = makeStore()
        let cal = Calendar.current
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        store.markDailySolved(date: yesterday, time: 120.0)
        store.markDailySolved(date: today, time: 90.0)

        XCTAssertEqual(store.currentStreak, 2)
        XCTAssertEqual(store.longestStreak, 2)
    }

    // MARK: - testStreak_brokenIfDayMissed

    /// Regression: load() must not blindly restore a stale currentStreak from disk.
    /// Scenario: disk has currentStreak=1 from two days ago (yesterday+today both missed).
    /// A fresh store must call updateStreak() during load() and return 0.
    func testStreak_brokenIfDayMissed() {
        let suite = "test.streak.broken.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!

        let cal = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let twoDaysAgo = df.string(from: cal.date(byAdding: .day, value: -2,
                                                   to: cal.startOfDay(for: Date()))!)

        // Manually craft a persisted snapshot that has currentStreak=1 but the
        // solve date is two days ago — simulates a user who solved, then missed a day.
        let json = """
        {
          "levelProgress": {},
          "dailyResults": [{"date": "\(twoDaysAgo)", "solved": true, "time": 60.0}],
          "currentStreak": 1,
          "longestStreak": 1
        }
        """
        ud.set(json.data(using: .utf8)!, forKey: suite)

        // Loading a fresh store must recalculate (NOT blindly restore) currentStreak.
        // Neither yesterday nor today is solved → streak must be 0.
        let store = ProgressStore(defaults: ud, key: suite)
        XCTAssertEqual(store.currentStreak, 0, "Streak must reset to 0 — a day was missed")
        XCTAssertEqual(store.longestStreak, 1, "Longest streak should be preserved from disk")
    }

    // MARK: - testPackCompletionCount

    func testPackCompletionCount_empty() {
        let store = makeStore()
        XCTAssertEqual(store.packCompletionCount("cozy-beginnings"), 0)
    }

    func testPackCompletionCount_afterSeveral() {
        let store = makeStore()
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 1, time: 60)
        store.markCompleted(levelId: "cozy-beginnings-2", stars: 2, time: 50)
        store.markCompleted(levelId: "cozy-beginnings-3", stars: 3, time: 30)
        store.markCompleted(levelId: "spice-route-1", stars: 1, time: 80)

        XCTAssertEqual(store.packCompletionCount("cozy-beginnings"), 3)
        XCTAssertEqual(store.packCompletionCount("spice-route"), 1)
        XCTAssertEqual(store.totalLevelsCompleted(), 4)
    }

    // MARK: - testAverageTime

    func testAverageTime_noCompletions() {
        let store = makeStore()
        XCTAssertEqual(store.averageTime(), 0)
    }

    func testAverageTime_withCompletions() {
        let store = makeStore()
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 1, time: 60)
        store.markCompleted(levelId: "cozy-beginnings-2", stars: 2, time: 100)

        XCTAssertEqual(store.averageTime(), 80, accuracy: 0.001)
    }

    // MARK: - testReset

    func testReset() {
        let store = makeStore()
        store.markCompleted(levelId: "cozy-beginnings-1", stars: 3, time: 25.0)
        store.markDailySolved(date: Date(), time: 60.0)

        XCTAssertEqual(store.totalLevelsCompleted(), 1)
        XCTAssertEqual(store.currentStreak, 1)

        store.reset()

        XCTAssertEqual(store.totalLevelsCompleted(), 0)
        XCTAssertEqual(store.currentStreak, 0)
        XCTAssertEqual(store.longestStreak, 0)
        XCTAssertTrue(store.levelProgress.isEmpty)
        XCTAssertTrue(store.dailyResults.isEmpty)
    }

    // MARK: - testPersistenceRoundTrip

    func testPersistenceRoundTrip() {
        let suite = "test.roundtrip.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!

        // Write in one store
        let store1 = ProgressStore(defaults: ud, key: suite)
        store1.markCompleted(levelId: "cozy-beginnings-1", stars: 2, time: 55.0)
        store1.markDailySolved(date: Date(), time: 70.0)

        // Read in a fresh store with same UserDefaults
        let store2 = ProgressStore(defaults: ud, key: suite)
        XCTAssertTrue(store2.isLevelCompleted("cozy-beginnings-1"))
        XCTAssertEqual(store2.levelProgress["cozy-beginnings-1"]?.stars, 2)
        XCTAssertEqual(store2.currentStreak, 1)
    }

    // MARK: - testUseHint (IOS-58)

    func testUseHint_decrementsCountAndReturnsTrue() {
        let store = makeStore()
        store.addHints(1)
        XCTAssertEqual(store.hintCount, 1, "precondition: 1 hint added")

        let result = store.useHint()

        XCTAssertTrue(result, "useHint should return true when hints remain")
        XCTAssertEqual(store.hintCount, 0, "hintCount should decrement to 0")
    }

    func testUseHint_returnsFalseWhenEmpty() {
        let store = makeStore()
        XCTAssertEqual(store.hintCount, 0, "precondition: no hints")

        let result = store.useHint()

        XCTAssertFalse(result, "useHint should return false when hintCount is 0")
        XCTAssertEqual(store.hintCount, 0, "hintCount must stay 0")
    }

    // MARK: - testComputeStars

    func testComputeStars_5x5() {
        XCTAssertEqual(GameViewModel.computeStars(seconds: 25, gridSize: 5), 3)
        XCTAssertEqual(GameViewModel.computeStars(seconds: 45, gridSize: 5), 2)
        XCTAssertEqual(GameViewModel.computeStars(seconds: 90, gridSize: 5), 1)
    }

    func testComputeStars_6x6() {
        XCTAssertEqual(GameViewModel.computeStars(seconds: 55, gridSize: 6), 3)
        XCTAssertEqual(GameViewModel.computeStars(seconds: 100, gridSize: 6), 2)
        XCTAssertEqual(GameViewModel.computeStars(seconds: 150, gridSize: 6), 1)
    }
}
