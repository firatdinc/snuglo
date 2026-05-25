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
// Aynı tarih için her zaman aynı Level döner (determinizm garantisi).

public enum DailyPuzzle {

    // MARK: - Public API

    /// Bugünün bulmacasını döndürür (device timezone kullanılır).
    public static func today(timezone: TimeZone = .current) -> Level {
        forDate(Date(), timezone: timezone)
    }

    /// Belirli bir tarih için bulmaca üretir.
    public static func forDate(_ date: Date, timezone: TimeZone = .current) -> Level {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        let comps = cal.dateComponents([.year, .month, .day, .weekday], from: date)

        let year    = comps.year    ?? 2026
        let month   = comps.month   ?? 1
        let day     = comps.day     ?? 1
        let weekday = comps.weekday ?? 2  // 1=Sun, 2=Mon … 7=Sat

        let seed = UInt64(year * 10000 + month * 100 + day)

        let gridSize: Int = {
            switch weekday {
            case 2, 6: return 5   // Mon, Fri
            case 3, 7: return 6   // Tue, Sat
            case 4, 1: return 7   // Wed, Sun
            case 5:    return 8   // Thu
            default:   return 5
            }
        }()

        let gen = LevelGenerator()
        return gen.generate(
            packId:     "daily",
            levelIndex: 0,
            gridSize:   gridSize,
            seedBase:   seed
        )
    }

    /// Verilen tarih için ham seed değerini döndürür (test/debug amacıyla).
    public static func seed(for date: Date, timezone: TimeZone = .current) -> UInt64 {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let year  = comps.year  ?? 2026
        let month = comps.month ?? 1
        let day   = comps.day   ?? 1
        return UInt64(year * 10000 + month * 100 + day)
    }
}
