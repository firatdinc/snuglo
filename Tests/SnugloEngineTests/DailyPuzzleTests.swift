import XCTest
@testable import SnugloEngine

final class DailyPuzzleTests: XCTestCase {

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int, timezone: TimeZone = .current) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        var comps = DateComponents()
        comps.year  = year
        comps.month = month
        comps.day   = day
        comps.hour  = 12
        return cal.date(from: comps)!
    }

    // MARK: - Tests

    /// today() → aynı seed → deterministik: 3 çağrı da özdeş Level.id döner.
    func testTodayDeterministic() {
        let tz = TimeZone(identifier: "Europe/Istanbul")!
        let a = DailyPuzzle.today(timezone: tz)
        let b = DailyPuzzle.today(timezone: tz)
        let c = DailyPuzzle.today(timezone: tz)
        XCTAssertEqual(a.id, b.id)
        XCTAssertEqual(b.id, c.id)
        // Piece sayısı sıfır olmamalı
        XCTAssertFalse(a.pieces.isEmpty)
    }

    /// 2026-01-01 Perşembe → gridSize == 8
    func testForDateThursdayGridSize8() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 1, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  8, "Thu → 8×8")
        XCTAssertEqual(level.height, 8, "Thu → 8×8")
    }

    /// 2026-01-05 Pazartesi → gridSize == 5
    func testForDateMondayGridSize5() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 5, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  5, "Mon → 5×5")
        XCTAssertEqual(level.height, 5, "Mon → 5×5")
    }

    /// 2026-01-06 Salı → gridSize == 6
    func testForDateTuesdayGridSize6() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 6, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  6, "Tue → 6×6")
        XCTAssertEqual(level.height, 6, "Tue → 6×6")
    }

    /// 2026-01-07 Çarşamba → gridSize == 7
    func testForDateWednesdayGridSize7() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 7, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  7, "Wed → 7×7")
        XCTAssertEqual(level.height, 7, "Wed → 7×7")
    }

    /// 2026-01-09 Cuma → gridSize == 5
    func testForDateFridayGridSize5() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 9, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  5, "Fri → 5×5")
    }

    /// 2026-01-10 Cumartesi → gridSize == 6
    func testForDateSaturdayGridSize6() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 10, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  6, "Sat → 6×6")
    }

    /// 2026-01-11 Pazar → gridSize == 7
    func testForDateSundayGridSize7() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 11, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.width,  7, "Sun → 7×7")
    }

    /// Farklı tarih → farklı Level (seed farklı → farklı piece konfigürasyonu)
    func testForDateDifferentSeedDifferentLevel() {
        let tz = TimeZone(identifier: "UTC")!
        // 2026-01-01 Thu (8×8) vs 2026-01-05 Mon (5×5) → farklı gridSize + farklı seed
        let jan1  = makeDate(year: 2026, month: 1, day: 1, timezone: tz)  // Thu → 8×8
        let jan5  = makeDate(year: 2026, month: 1, day: 5, timezone: tz)  // Mon → 5×5
        let lvl1 = DailyPuzzle.forDate(jan1, timezone: tz)
        let lvl5 = DailyPuzzle.forDate(jan5, timezone: tz)
        // En azından grid boyutları farklı olmalı
        XCTAssertNotEqual(lvl1.width, lvl5.width, "Farklı tarih → farklı gridSize")
        // Seed değerleri farklı olmalı
        XCTAssertNotEqual(DailyPuzzle.seed(for: jan1, timezone: tz),
                          DailyPuzzle.seed(for: jan5, timezone: tz),
                          "Farklı tarih → farklı seed")
        // Parça sayısı da farklı olmalı (8×8 vs 5×5)
        let cells1 = lvl1.pieces.map { $0.cells.count }.reduce(0, +)
        let cells5 = lvl5.pieces.map { $0.cells.count }.reduce(0, +)
        XCTAssertNotEqual(cells1, cells5, "Farklı grid → farklı hücre sayısı")
    }

    /// seed(for:) doğru değer üretmeli: 2026-01-01 → 20260101
    func testSeedCalculation() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 1, timezone: tz)
        let s = DailyPuzzle.seed(for: date, timezone: tz)
        XCTAssertEqual(s, 20_260_101)
    }

    /// forDate ile üretilen Level'ın piece'leri grid'i tam kaplar.
    func testGeneratedLevelIsValid() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 1, timezone: tz)  // Thu → 8×8
        let level = DailyPuzzle.forDate(date, timezone: tz)
        // piece hücre toplamı == gridSize²
        let totalCells = level.pieces.map { $0.cells.count }.reduce(0, +)
        XCTAssertEqual(totalCells, 8 * 8, "8×8 grid 64 hücre içermeli")
    }

    /// Daily puzzle id her zaman "daily-0" formatında
    func testLevelIdFormat() {
        let tz = TimeZone(identifier: "UTC")!
        let date = makeDate(year: 2026, month: 1, day: 5, timezone: tz)
        let level = DailyPuzzle.forDate(date, timezone: tz)
        XCTAssertEqual(level.id, "daily-0")
    }

    // MARK: - UTC Enforcement (BLOCKER D2 fix)

    /// UTC zorunluluk testi: aynı Date, farklı timezone parametresi → özdeş Level.
    ///
    /// 2026-01-01T22:00:00Z noktasında:
    ///   - UTC  → hâlâ 1 Ocak  (weekday: Thu → 8×8, seed: 20260101)
    ///   - UTC+3 Istanbul → 2 Ocak (weekday: Fri → 5×5, seed: 20260102 olurdu)
    ///
    /// DailyPuzzle UTC kullandığından, timezone parametresi ne olursa olsun
    /// UTC 1 Ocak puzzle'ı (8×8) döner. Bu test UTC enforcement'ı kilitler.
    func testUTCEnforced_sameDate_differentTimezoneParam_samePuzzle() {
        // 2026-01-01 22:00 UTC — Türkiye'de artık 2 Ocak 01:00
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1; comps.hour = 22
        let date22UTC = utcCal.date(from: comps)!

        let istanbulTZ = TimeZone(identifier: "Europe/Istanbul")!  // UTC+3

        // Her iki çağrı da UTC 1 Ocak bulmacası (Thu → 8×8) döndürmeli
        let levelUTC      = DailyPuzzle.forDate(date22UTC)
        let levelIstanbul = DailyPuzzle.forDate(date22UTC, timezone: istanbulTZ)

        XCTAssertEqual(levelUTC.id,    levelIstanbul.id,
                       "UTC enforcement: timezone parametresi sonucu değiştirmemeli")
        XCTAssertEqual(levelUTC.width, levelIstanbul.width,
                       "Aynı gridSize (UTC 8×8 Thu) timezone'dan bağımsız")
        XCTAssertEqual(levelUTC.width, 8,
                       "UTC 2026-01-01 Thu → gridSize=8")

        // Seed de UTC baz almalı
        let seedUTC      = DailyPuzzle.seed(for: date22UTC)
        let seedIstanbul = DailyPuzzle.seed(for: date22UTC, timezone: istanbulTZ)
        XCTAssertEqual(seedUTC, seedIstanbul,
                       "Seed her zaman UTC'den hesaplanmalı")
        XCTAssertEqual(seedUTC, 20_260_101,
                       "2026-01-01 UTC → seed=20260101")

        // gridSize(for:) de UTC baz almalı
        let gUTC      = DailyPuzzle.gridSize(for: date22UTC)
        XCTAssertEqual(gUTC, 8, "gridSize(for:) UTC 2026-01-01 Thu → 8")
    }

    /// SolutionChecker doğrulaması: her daily puzzle'ın solution'ı geçerli olmalı.
    func testDailyPuzzleSolutionIsValid() {
        let checker = SolutionChecker()
        let utc = TimeZone(identifier: "UTC")!
        // Haftanın 7 günü için ayrı ayrı doğrula
        let dates = (1...7).map { makeDate(year: 2026, month: 1, day: $0, timezone: utc) }
        for date in dates {
            let level = DailyPuzzle.forDate(date)
            let result = checker.check(level: level, placements: level.solution)
            XCTAssertEqual(result, .valid,
                           "daily-\(date) solution geçerli değil: \(result)")
        }
    }
}
