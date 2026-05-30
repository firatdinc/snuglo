import XCTest
@testable import SnugloApp

final class DailyDealRotatorTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return calendar.date(from: comps)!
    }

    private let deals = DailyDeal.allDeals

    // MARK: — Empty guard

    func test_emptyOffers_returnsNil() {
        let result = DailyDealRotator.deal(forDate: Date(), calendar: calendar, offers: [])
        XCTAssertNil(result)
    }

    // MARK: — Determinism

    func test_sameDayTwoCalls_returnSameDeal() {
        let date = makeDate(year: 2026, month: 5, day: 30)
        let a = DailyDealRotator.deal(forDate: date, calendar: calendar, offers: deals)
        let b = DailyDealRotator.deal(forDate: date, calendar: calendar, offers: deals)
        XCTAssertEqual(a?.id, b?.id)
    }

    func test_consecutiveDays_mayDiffer() {
        // At least one consecutive pair should differ across 5 deals.
        var seen = Set<String>()
        for day in 1...10 {
            let date = makeDate(year: 2026, month: 1, day: day)
            if let d = DailyDealRotator.deal(forDate: date, calendar: calendar, offers: deals) {
                seen.insert(d.id)
            }
        }
        XCTAssertGreaterThan(seen.count, 1, "Expected multiple distinct deals across 10 days")
    }

    // MARK: — Coverage

    func test_allDealsReachable_across365Days() {
        var seen = Set<String>()
        for day in 0..<365 {
            let date = calendar.date(byAdding: .day, value: day, to: makeDate(year: 2026, month: 1, day: 1))!
            if let d = DailyDealRotator.deal(forDate: date, calendar: calendar, offers: deals) {
                seen.insert(d.id)
            }
        }
        let allIDs = Set(deals.map(\.id))
        XCTAssertEqual(seen, allIDs, "All deals should be reachable within a year")
    }

    // MARK: — Single-offer list

    func test_singleOffer_alwaysReturnsIt() {
        let only = [DailyDeal.allDeals[0]]
        for day in 1...31 {
            let date = makeDate(year: 2026, month: 3, day: day)
            let result = DailyDealRotator.deal(forDate: date, calendar: calendar, offers: only)
            XCTAssertEqual(result?.id, only[0].id)
        }
    }

    // MARK: — Known anchor

    func test_knownDate_returnsExpectedIndex() {
        // year=2026, month=5, day=30 → hash = 2026*366 + 5*31 + 30 = 741516 + 155 + 30 = 741701
        // 741701 % 5 = 1  → deals[1]
        let date = makeDate(year: 2026, month: 5, day: 30)
        let result = DailyDealRotator.deal(forDate: date, calendar: calendar, offers: deals)
        XCTAssertEqual(result?.id, deals[741701 % deals.count].id)
    }
}
