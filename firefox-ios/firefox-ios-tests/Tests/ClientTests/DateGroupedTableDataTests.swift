// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared

final class DateGroupedTableDataTests: XCTestCase {
    // Timestamps that fall in the middle of the default time intervals
    let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()

    // Timestamps for custom intervals
    let lastHour = Date()
    let lastMonth = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    let older = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
    let customTimeStamps = [Date().lastHour.timeIntervalSince1970, Date().lastMonth.timeIntervalSince1970]

    // MARK: - Tests not including "Last Hour" section

    // Adds entry to "Last 24 Hours" section
    func testAddNow() {
        var subject = DateGroupedTableData<String>()
        subject.add("Now", timestamp: Date().timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Now"])
    }

    // Adds entry to "Last 24 Hours" section
    func testAddTwelveHoursAgo() {
        var subject = DateGroupedTableData<String>()
        subject.add("Twelve Hours Ago", timestamp: twelveHoursAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Twelve Hours Ago"])
    }

    // Adds entry to "Last 7 Days" section
    func testaddThreeDaysAgo() {
        var subject = DateGroupedTableData<String>()
        subject.add("Three Days Ago", timestamp: threeDaysAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(1), ["Three Days Ago"])
    }

    // Adds entry to "Last 4 Weeks" section
    func testAddTwoWeeksAgo() {
        var subject = DateGroupedTableData<String>()
        subject.add("Two Weeks Ago", timestamp: twoWeeksAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(2), ["Two Weeks Ago"])
    }

    // Adds entry to "Older" section
    func testAddTwoMonthsAgo() {
        var subject = DateGroupedTableData<String>()
        subject.add("Two Months Ago", timestamp: twoMonthsAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(3), ["Two Months Ago"])
    }

    func testRemove() {
        var subject = DateGroupedTableData<String>()
        subject.add("Three Days Ago (1)", timestamp: threeDaysAgo.timeIntervalSince1970)
        subject.add("Three Days Ago (2)", timestamp: threeDaysAgo.timeIntervalSince1970)

        subject.remove("Three Days Ago (1)")

        XCTAssertEqual(subject.itemsForSection(1), ["Three Days Ago (2)"])
    }

    // MARK: - Tests including "Last Hour" section (used in history panel)

    // Adds entry to "Last Hour" section
    func testIncludeLastHour_AddNow() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Now", timestamp: Date().timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Now"])
    }

    // Adds entry to "Last 24 Hours" section
    func testIncludeLastHour_AddTwelveHoursAgo() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Twelve Hours Ago", timestamp: twelveHoursAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(1), ["Twelve Hours Ago"])
    }

    // Adds entry to "Last 7 Days" section
    func testIncludeLastHour_AddThreeDaysAgo() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Three Days Ago", timestamp: threeDaysAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(2), ["Three Days Ago"])
    }

    // Adds entry to "Last 4 Weeks" section
    func testIncludeLastHour_AddTwoWeeksAgo() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Two Weeks Ago", timestamp: twoWeeksAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(3), ["Two Weeks Ago"])
    }

    // Adds entry to "Older" section
    func testIncludeLastHour_AddTwoMonthsAgo() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Two Months Ago", timestamp: twoMonthsAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(4), ["Two Months Ago"])
    }

    func testIncludeLastHour_Remove() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Three Days Ago (1)", timestamp: threeDaysAgo.timeIntervalSince1970)
        subject.add("Three Days Ago (2)", timestamp: threeDaysAgo.timeIntervalSince1970)

        subject.remove("Three Days Ago (1)")

        XCTAssertEqual(subject.itemsForSection(2), ["Three Days Ago (2)"])
    }

    // MARK: - Test general functions

    func testAllItems() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Last Hour", timestamp: Date().timeIntervalSince1970)
        subject.add("Last 24 Hours", timestamp: twelveHoursAgo.timeIntervalSince1970)
        subject.add("Last 7 Days", timestamp: threeDaysAgo.timeIntervalSince1970)
        subject.add("Last 4 Weeks", timestamp: twoWeeksAgo.timeIntervalSince1970)
        subject.add("Older", timestamp: twoMonthsAgo.timeIntervalSince1970)

        XCTAssertEqual(subject.allItems(), ["Last Hour",
                                            "Last 24 Hours",
                                            "Last 7 Days",
                                            "Last 4 Weeks",
                                            "Older"])
    }

    func testIsEmptySucceeds() {
        let subject = DateGroupedTableData<String>(includeLastHour: true)
        XCTAssertTrue(subject.isEmpty)
    }

    func testIsEmptyFails() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Last Hour", timestamp: lastHour.timeIntervalSince1970)
        XCTAssertFalse(subject.isEmpty)
    }

    func testNumberOfItemsForSection() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Now1", timestamp: Date().timeIntervalSince1970)
        subject.add("Now2", timestamp: Date().timeIntervalSince1970)

        XCTAssertEqual(subject.numberOfItemsForSection(0), 2)
    }

    func testItemsForSection() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Now1", timestamp: Date().timeIntervalSince1970)
        subject.add("Now2", timestamp: Date().timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Now1", "Now2"])
    }

    // MARK: - Test custom intervals

    func testCustomIntervalsCreation() {
        let subject = DateGroupedTableData<String>(timestamps: customTimeStamps)

        XCTAssertEqual(subject.timestamps.count, 2)
        XCTAssertEqual(subject.timestampData.count, 3)
    }

    func testCustomIntervalsItemsForSection () {
        var subject = DateGroupedTableData<String>(timestamps: customTimeStamps)

        subject.add("Last Hour", timestamp: lastHour.timeIntervalSince1970)
        subject.add("Last Month", timestamp: lastMonth.timeIntervalSince1970)
        subject.add("Older", timestamp: older.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Last Hour"])
        XCTAssertEqual(subject.itemsForSection(1), ["Last Month"])
        XCTAssertEqual(subject.itemsForSection(2), ["Older"])
    }

    func testCustomIntervalsAdd() {
        var subject = DateGroupedTableData<String>(timestamps: customTimeStamps)

        subject.add("Last Hour", timestamp: lastHour.timeIntervalSince1970)
        subject.add("Last Month", timestamp: lastMonth.timeIntervalSince1970)
        subject.add("Older", timestamp: older.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Last Hour"])
        XCTAssertEqual(subject.itemsForSection(1), ["Last Month"])
        XCTAssertEqual(subject.itemsForSection(2), ["Older"])
    }

    func testCustomIntervalsRemove() {
        var subject = DateGroupedTableData<String>(timestamps: customTimeStamps)

        subject.add("Last Hour", timestamp: lastHour.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Last Hour"])

        subject.remove("Last Hour")

        XCTAssertEqual(subject.itemsForSection(0), [])
    }
}
