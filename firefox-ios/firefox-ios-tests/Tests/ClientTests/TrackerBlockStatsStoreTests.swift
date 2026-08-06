// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class TrackerBlockStatsStoreTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    override func tearDown() {
        prefs = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - Recording within a week

    func testRecord_accumulatesWithinSameISOWeek() {
        let subject = createSubject()
        let monday = makeDate(year: 2024, month: 6, day: 10)
        let friday = makeDate(year: 2024, month: 6, day: 14)

        subject.record(category: .advertising, count: 2, date: monday)
        subject.record(category: .advertising, count: 3, date: friday)

        XCTAssertEqual(subject.lifetimeTotal(), 5)
        XCTAssertEqual(subject.currentWeekTotal(for: monday), 5)
    }

    func testRecord_attributesPerCategory() {
        let subject = createSubject()
        let date = makeDate(year: 2024, month: 6, day: 10)

        subject.record(category: .advertising, count: 2, date: date)
        subject.record(category: .analytics, count: 4, date: date)
        subject.record(category: .social, count: 1, date: date)

        XCTAssertEqual(subject.lifetimeByCategory()[.advertising], 2)
        XCTAssertEqual(subject.lifetimeByCategory()[.analytics], 4)
        XCTAssertEqual(subject.lifetimeByCategory()[.social], 1)
        XCTAssertNil(subject.lifetimeByCategory()[.cryptomining])
        XCTAssertEqual(subject.lifetimeTotal(), 7)
    }

    func testRecord_ignoresNonPositiveCounts() {
        let subject = createSubject()
        let date = makeDate(year: 2024, month: 6, day: 10)

        subject.record(category: .advertising, count: 0, date: date)
        subject.record(category: .advertising, count: -5, date: date)

        XCTAssertEqual(subject.lifetimeTotal(), 0)
        XCTAssertTrue(subject.lifetimeByCategory().isEmpty)
        XCTAssertNil(subject.trackingStartDate(), "Ignored records must not start tracking")
    }

    // MARK: - Week boundaries

    func testRecord_crossingWeekBoundaryFoldsPreviousWeekIntoLifetime() {
        let subject = createSubject()
        let week24 = makeDate(year: 2024, month: 6, day: 14)
        let week25 = makeDate(year: 2024, month: 6, day: 17)

        subject.record(category: .advertising, count: 3, date: week24)
        subject.record(category: .advertising, count: 8, date: week25)

        XCTAssertEqual(subject.lifetimeTotal(), 11, "Lifetime is the sum of both weeks")
        XCTAssertEqual(subject.currentWeekTotal(for: week24), 0, "The previous week is no longer the current week")
        XCTAssertEqual(subject.currentWeekTotal(for: week25), 8, "Only the in-progress week is reported")
    }

    func testRecord_acrossISOYearRolloverFoldsPreviousWeekIntoLifetime() {
        let subject = createSubject()
        // 2020-12-31 falls in ISO week 53 of 2020; 2021-01-04 is ISO week 1 of 2021.
        let lastWeekOf2020 = makeDate(year: 2020, month: 12, day: 31)
        let firstWeekOf2021 = makeDate(year: 2021, month: 1, day: 4)

        subject.record(category: .analytics, count: 6, date: lastWeekOf2020)
        subject.record(category: .analytics, count: 9, date: firstWeekOf2021)

        XCTAssertEqual(subject.lifetimeTotal(), 15)
        XCTAssertEqual(subject.currentWeekTotal(for: lastWeekOf2020), 0)
        XCTAssertEqual(subject.currentWeekTotal(for: firstWeekOf2021), 9)
    }

    // MARK: - Current week

    func testCurrentWeekByCategory_reflectsOnlyTheInProgressWeek() {
        let subject = createSubject()
        let thisWeek = makeDate(year: 2024, month: 6, day: 10)
        let nextWeek = makeDate(year: 2024, month: 6, day: 17)

        subject.record(category: .advertising, count: 2, date: thisWeek)
        subject.record(category: .social, count: 5, date: nextWeek)

        // Once the week rolls over, the earlier week is folded away and no longer
        // reported per-week; only the in-progress week remains queryable.
        XCTAssertEqual(subject.currentWeekByCategory(for: thisWeek), [:])
        XCTAssertEqual(subject.currentWeekByCategory(for: nextWeek), [.social: 5])
    }

    func testCurrentWeekTotal_returnsZeroForNonCurrentWeek() {
        let subject = createSubject()
        subject.record(category: .advertising, count: 2, date: makeDate(year: 2024, month: 6, day: 10))

        let otherWeek = makeDate(year: 2024, month: 1, day: 1)
        XCTAssertEqual(subject.currentWeekTotal(for: otherWeek), 0)
        XCTAssertTrue(subject.currentWeekByCategory(for: otherWeek).isEmpty)
    }

    // MARK: - Lifetime across rollovers

    func testLifetimeAndCurrentWeek_correctAfterWeekRollovers() {
        let subject = createSubject()
        let week1 = makeDate(year: 2024, month: 6, day: 3)
        let week2 = makeDate(year: 2024, month: 6, day: 10)
        let week3 = makeDate(year: 2024, month: 6, day: 17)

        subject.record(category: .advertising, count: 2, date: week1)
        subject.record(category: .analytics, count: 5, date: week2)
        subject.record(category: .advertising, count: 3, date: week3)

        XCTAssertEqual(subject.lifetimeTotal(), 10)
        XCTAssertEqual(subject.currentWeekTotal(for: week1), 0, "A folded week is no longer the current week")
        XCTAssertEqual(subject.currentWeekTotal(for: week2), 0)
        XCTAssertEqual(subject.currentWeekTotal(for: week3), 3, "Current in-progress week")
        XCTAssertEqual(subject.lifetimeByCategory()[.advertising], 5)
        XCTAssertEqual(subject.lifetimeByCategory()[.analytics], 5)
    }

    func testStorage_staysFixedSizeAcrossManyWeeks() {
        let subject = createSubject()
        // Record one hit per week across ~15 weeks (day values overflow the month
        // and are normalized by the calendar into successive weeks).
        for day in stride(from: 1, through: 99, by: 7) {
            subject.record(category: .advertising, count: 1, date: makeDate(year: 2024, month: 1, day: day))
        }

        // The hot-path value must never accumulate history: it holds exactly one week.
        let current = decodeCurrentWeek()
        XCTAssertNotNil(current)
        XCTAssertEqual(current?.counts.values.reduce(0, +), 1, "Current week holds only the most recent week")

        // All completed weeks collapse into a single running total, not a growing list.
        let lifetime = decodeLifetime()
        XCTAssertEqual(lifetime.counts.count, 1, "Running total is keyed by category only, not by week")
        XCTAssertEqual(subject.lifetimeTotal(), 15)
    }

    // MARK: - Start date

    func testTrackingStartDate_isSetToFirstRecordedDate() {
        let subject = createSubject()
        let firstDate = makeDate(year: 2024, month: 6, day: 10)

        subject.record(category: .advertising, count: 1, date: firstDate)

        XCTAssertEqual(subject.trackingStartDate()?.toTimestamp(), firstDate.toTimestamp())
    }

    func testTrackingStartDate_isNotOverwrittenByLaterRecords() {
        let subject = createSubject()
        let firstDate = makeDate(year: 2024, month: 6, day: 10)
        let laterWeek = makeDate(year: 2024, month: 6, day: 17)

        subject.record(category: .advertising, count: 1, date: firstDate)
        subject.record(category: .analytics, count: 1, date: laterWeek)

        XCTAssertEqual(subject.trackingStartDate()?.toTimestamp(), firstDate.toTimestamp())
    }

    func testTrackingStartDate_persistsAcrossStoreInstances() {
        let firstDate = makeDate(year: 2024, month: 6, day: 10)
        let first = createSubject()
        first.record(category: .advertising, count: 1, date: firstDate)

        let second = createSubject()
        XCTAssertEqual(second.trackingStartDate()?.toTimestamp(), firstDate.toTimestamp())
    }

    // MARK: - Reset

    func testReset_clearsAllStats() {
        let subject = createSubject()
        let date = makeDate(year: 2024, month: 6, day: 10)
        subject.record(category: .advertising, count: 2, date: date)

        subject.reset()

        XCTAssertEqual(subject.lifetimeTotal(), 0)
        XCTAssertEqual(subject.currentWeekTotal(for: date), 0)
        XCTAssertTrue(subject.lifetimeByCategory().isEmpty)
        XCTAssertNil(subject.trackingStartDate())
    }

    // MARK: - Reported-figures high-water mark

    func testHighestReportedFigures_defaultsToZeroAndPersists() {
        let subject = createSubject()
        XCTAssertEqual(subject.highestReportedFigures(), 0)

        subject.setHighestReportedFigures(6)

        // A brand-new store backed by the same prefs must read the same value.
        XCTAssertEqual(createSubject().highestReportedFigures(), 6)
    }

    func testReset_clearsHighestReportedFigures() {
        let subject = createSubject()
        subject.setHighestReportedFigures(7)

        subject.reset()

        XCTAssertEqual(subject.highestReportedFigures(), 0)
    }

    // MARK: - Persistence

    func testRecordedStats_persistAcrossStoreInstances() {
        let date = makeDate(year: 2024, month: 6, day: 10)
        let first = createSubject()
        first.record(category: .advertising, count: 4, date: date)

        // A brand-new store backed by the same prefs must read the same data.
        let second = createSubject()

        XCTAssertEqual(second.lifetimeTotal(), 4)
        XCTAssertEqual(second.currentWeekTotal(for: date), 4)
        XCTAssertEqual(second.lifetimeByCategory()[.advertising], 4)
    }

    // MARK: - Helpers

    private func createSubject() -> DefaultTrackerBlockStatsStoreUtility {
        return DefaultTrackerBlockStatsStoreUtility(prefs: prefs, calendar: calendar)
    }

    private func decodeCurrentWeek() -> TrackerBlockStatsBucket? {
        return decode(TrackerBlockStatsBucket.self, forKey: PrefsKeys.TrackerBlockStatsCurrentWeek)
    }

    private func decodeLifetime() -> TrackerBlockStatsRunningTotal {
        return decode(TrackerBlockStatsRunningTotal.self, forKey: PrefsKeys.TrackerBlockStatsLifetime)
            ?? TrackerBlockStatsRunningTotal()
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let json = prefs.stringForKey(key), let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        guard let date = calendar.date(from: components) else {
            fatalError("Invalid test date \(year)-\(month)-\(day)")
        }
        return date
    }
}
