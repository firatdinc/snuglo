import Foundation

struct DailyDealRotator {

    /// Returns the deal for the given calendar date.
    ///
    /// Selection is deterministic: the same year-month-day always maps to the
    /// same index. Uses `abs(year×366 + month×31 + day) % offers.count`.
    /// Returns `nil` only when `offers` is empty.
    static func deal(
        forDate date: Date,
        calendar: Calendar = .current,
        offers: [DailyDeal]
    ) -> DailyDeal? {
        guard !offers.isEmpty else { return nil }
        let year  = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day   = calendar.component(.day, from: date)
        let hash  = year &* 366 &+ month &* 31 &+ day
        return offers[abs(hash) % offers.count]
    }
}
