// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared

final class DateGroupedTableDataTests: XCTestCase {
    let lastHour = Date()
    let today = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    let yesterday = Date().dayBefore
    let lastWeek = Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
    let lastMonth = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    let older = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
    let customTimeStamps = [Date().lastHour.timeIntervalSince1970, Date().lastMonth.timeIntervalSince1970]

    func testIncludeLastHourAddNow() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Now", timestamp: Date().timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Now"])
    }

    func testAddNow() {
        var subject = DateGroupedTableData<String>()
        subject.add("Now", timestamp: Date().timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["Now"])
    }

    func testAddOneHourAgo() {
        var subject = DateGroupedTableData<String>()
        subject.add("One Hour Ago", timestamp: lastHour.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(0), ["One Hour Ago"])
    }

    func testAddYesterday() {
        var subject = DateGroupedTableData<String>()
        subject.add("Yesterday", timestamp: yesterday.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(1), ["Yesterday"])
    }

    func testAddOlder() {
        var subject = DateGroupedTableData<String>()
        subject.add("Older", timestamp: older.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(4), ["Older"])
    }

    func testIncludeLastHourRemove() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Yesterday1", timestamp: yesterday.timeIntervalSince1970)
        subject.add("Yesterday2", timestamp: yesterday.timeIntervalSince1970)

        subject.remove("Yesterday1")

        XCTAssertEqual(subject.itemsForSection(2), ["Yesterday2"])
    }

    func testAllItems() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Last Hour", timestamp: lastHour.timeIntervalSince1970)
        subject.add("Today", timestamp: today.timeIntervalSince1970)
        subject.add("Yesterday", timestamp: yesterday.timeIntervalSince1970)
        subject.add("Last Week", timestamp: lastWeek.timeIntervalSince1970)
        subject.add("Last Month", timestamp: lastMonth.timeIntervalSince1970)
        subject.add("Older", timestamp: older.timeIntervalSince1970)

        XCTAssertEqual(subject.allItems(), ["Last Hour",
                                            "Today",
                                            "Yesterday",
                                            "Last Week",
                                            "Last Month",
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
        subject.add("Yesterday1", timestamp: yesterday.timeIntervalSince1970)
        subject.add("Yesterday2", timestamp: yesterday.timeIntervalSince1970)

        XCTAssertEqual(subject.numberOfItemsForSection(2), 2)
    }

    func testItemsForSection() {
        var subject = DateGroupedTableData<String>(includeLastHour: true)
        subject.add("Yesterday1", timestamp: yesterday.timeIntervalSince1970)
        subject.add("Yesterday2", timestamp: yesterday.timeIntervalSince1970)

        XCTAssertEqual(subject.itemsForSection(2), ["Yesterday1", "Yesterday2"])
    }

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
