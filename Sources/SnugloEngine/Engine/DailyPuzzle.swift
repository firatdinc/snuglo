import Foundation

// MARK: - DailyPuzzle
//
// Tarih-tabanlı deterministik bulmaca üretici.
//
// Seed: year * 10000 + month * 100 + day  (örn. 2026-01-01 → 20260101)
// Grid boyutu haftalık rotasyon (weekday 1=Sun…7=Sat):
//   Mon(2), Fri(6) → 5×5
//   Tue(3), Sat(7) → 6×6
//   Wed(4), Sun(1) → 7×7
//   Thu(5)         → 8×8
//
// UTC ZORUNLU: DateComponents her zaman UTC Calendar ile çıkarılır.
// `timezone` parametresi API uyumluluğu için kabul edilir ama
// dahili hesaplamalarda UTC kullanılır (BLOCKER D2 reviewer fix).
// Bu, farklı timezone'lardaki cihazların her zaman aynı günlük
// bulmacayı görmesini garanti eder.

private let _utcCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}()

public enum DailyPuzzle {

    // MARK: - Public API

    /// Bugünün bulmacasını döndürür.
    ///
    /// - Parameter timezone: API uyumluluğu için kabul edilir; dahili hesaplamalar
    ///   her zaman UTC kullanır (cross-timezone determinizm garantisi).
    public static func today(index: Int = 0, timezone: TimeZone = .current) -> Level {
        forDate(Date(), index: index)
    }

    /// Belirli bir tarih için bulmaca üretir.
    ///
    /// - Parameters:
    ///   - date: Hedef tarih (herhangi bir saat diliminde temsil edilebilir).
    ///   - timezone: API uyumluluğu için kabul edilir; kullanılmaz.
    ///     DateComponents her zaman UTC'den çıkarılır (reviewer BLOCKER D2 fix).
    ///
    /// **Regression lock:** 2026-01-01 Perşembe → gridSize=8, seed=20260101.
    ///
    /// - Parameter index: Günün kaçıncı bölümü (0-tabanlı). Aynı gün içinde
    ///   farklı `index` → farklı (ve `levelIndex` arttıkça daha zor) bulmaca.
    ///   Üretilen `Level.id` = `"daily-<index>"`. `index: 0` eski davranışı korur.
    public static func forDate(_ date: Date, index: Int = 0, timezone: TimeZone = .current) -> Level {
        // UTC ZORUNLU — timezone parametresi yok sayılır
        let comps = _utcCalendar.dateComponents([.year, .month, .day, .weekday], from: date)

        let year    = comps.year    ?? 2026
        let month   = comps.month   ?? 1
        let day     = comps.day     ?? 1
        let weekday = comps.weekday ?? 2  // 1=Sun, 2=Mon … 7=Sat

        let s       = UInt64(year * 10000 + month * 100 + day)
        let gs      = gridSize(forWeekday: weekday)

        let gen = LevelGenerator()
        return gen.generate(
            packId: "daily",
            levelIndex: index,
            gridSize: gs,
            seedBase: s
        )
    }

    /// Verilen tarih için ham UTC seed değerini döndürür (test / debug).
    ///
    /// - Parameter timezone: API uyumluluğu için kabul edilir; dahili olarak UTC kullanılır.
    /// - Returns: `year*10000 + month*100 + day` (UTC baz).
    public static func seed(for date: Date, timezone: TimeZone = .current) -> UInt64 {
        // UTC ZORUNLU — timezone parametresi yok sayılır
        let comps = _utcCalendar.dateComponents([.year, .month, .day], from: date)
        let year  = comps.year  ?? 2026
        let month = comps.month ?? 1
        let day   = comps.day   ?? 1
        return UInt64(year * 10000 + month * 100 + day)
    }

    /// UTC weekday'e göre grid boyutu döner.
    ///
    /// Rotasyon (Calendar.component .weekday, 1=Sun):
    ///
    /// | Weekday | Gün | Size |
    /// |---------|-----|------|
    /// | 1       | Sun | 7×7  |
    /// | 2       | Mon | 5×5  |
    /// | 3       | Tue | 6×6  |
    /// | 4       | Wed | 7×7  |
    /// | 5       | Thu | 8×8  |
    /// | 6       | Fri | 5×5  |
    /// | 7       | Sat | 6×6  |
    ///
    /// Regression lock: 2026-01-01 Perşembe (weekday=5) → 8 ✓
    public static func gridSize(for date: Date) -> Int {
        let weekday = _utcCalendar.component(.weekday, from: date)
        return gridSize(forWeekday: weekday)
    }

    // MARK: - Internal

    static func gridSize(forWeekday weekday: Int) -> Int {
        switch weekday {
        case 2, 6: return 5   // Mon, Fri
        case 3, 7: return 6   // Tue, Sat
        case 4, 1: return 7   // Wed, Sun
        case 5:    return 8   // Thu
        default:   return 5
        }
    }
}
