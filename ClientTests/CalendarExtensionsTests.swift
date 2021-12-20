// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class CalendarExtensionsTests: XCTestCase {

    // MARK: add(numberOfDays:to)

    func testAddZeroDay_returnSameDate() {
        let calendar = Calendar.current
        let currentDate = Date()
        let resultDate = calendar.add(numberOfDays: 0, to: currentDate)
        XCTAssertEqual(currentDate, resultDate)
    }

    func testAddOneDay_returnsNextDay() {
        let calendar = Calendar.current
        let currentDate = Date()
        let expectedDay = currentDate.dayAfter

        let resultDate = calendar.add(numberOfDays: 1, to: currentDate)!
        let result = calendar.compare(expectedDay, to: resultDate, toGranularity: .day)
        XCTAssertEqual(result, .orderedSame)
    }

    func testRemoveOneDay_returnsPastDay() {
        let calendar = Calendar.current
        let currentDate = Date()
        let expectedDay = currentDate.dayBefore

        let resultDate = calendar.add(numberOfDays: -1, to: currentDate)!
        let result = calendar.compare(expectedDay, to: resultDate, toGranularity: .day)
        XCTAssertEqual(result, .orderedSame)
    }

    // MARK: numberOfDaysBetween(from:to)

    func testNumberOfDays_sameDateReturnsZero() {
        let calendar = Calendar.current
        let currentDate = Date()
        let resultNumber = calendar.numberOfDaysBetween(currentDate,
                                                        and: currentDate)
        XCTAssertEqual(resultNumber, 0)
    }

    func testNumberOfDays_nextDayReturnsOne() {
        let calendar = Calendar.current
        let currentDate = Date()
        let nextDate = currentDate.dayAfter
        let resultNumber = calendar.numberOfDaysBetween(currentDate,
                                                        and: nextDate)
        XCTAssertEqual(resultNumber, 1)
    }

    func testNumberOfDays_dayAfterTomorrowReturnsTwo() {
        let calendar = Calendar.current
        let currentDate = Date()
        let dayAfterTomorrowDate = currentDate.dayAfter.dayAfter
        let resultNumber = calendar.numberOfDaysBetween(currentDate,
                                                        and: dayAfterTomorrowDate)
        XCTAssertEqual(resultNumber, 2)
    }
}
