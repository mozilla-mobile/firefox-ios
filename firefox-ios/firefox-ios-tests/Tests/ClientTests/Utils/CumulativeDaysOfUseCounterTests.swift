// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class CumulativeDaysOfUseCounterTests: XCTestCase {
    private var calendar: Calendar!
    private var counter: CumulativeDaysOfUseCounter!

    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        counter = CumulativeDaysOfUseCounter()
        counter.reset()
    }

    override func tearDown() {
        counter = nil
        calendar = nil
        super.tearDown()
    }

    func testByDefaultCounter_isFalse() {
        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertNil(counter.daysOfUse)
    }

    func testUpdateCounterOnce_isFalse() {
        counter.updateCounter()
        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 1)
    }

    func testUpdateCounter5TimesSameDay_isFalse() {
        for _ in 0...5 {
            counter.updateCounter()
        }

        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 1)
    }

    func testUpdateCounterMoreThan5TimesSameDay_isFalse() {
        for _ in 0...10 {
            counter.updateCounter()
        }

        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 1)
    }

    func testUpdateCounterFiveTimeDifferentDaysWithOneDayBetween_isFalse() {
        let currentDate = Date()
        addUsageDays(from: 0, to: 2, currentDate: currentDate)
        addUsageDays(from: 4, to: 5, currentDate: currentDate)

        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)
    }

    func testUpdateCounterFiveTimeDifferentDaysWithDaysBetween_isFalse() {
        let currentDate = Date()
        addUsageDays(from: 1, to: 2, currentDate: currentDate)
        addUsageDays(from: 6, to: 8, currentDate: currentDate)

        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 4)
    }

    func testUpdateCounterFiveTimeDifferentDaysInARow_isTrue() {
        let currentDate = Date()
        addUsageDays(from: 0, to: 4, currentDate: currentDate)

        XCTAssertTrue(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)
    }

    func testUpdateCounterFiveTimeValidWithinSevenDays_isTrue() {
        let currentDate = Date()
        addUsageDays(from: 0, to: 4, currentDate: currentDate)
        addUsageDays(from: 6, to: 6, currentDate: currentDate)

        XCTAssertTrue(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 6)
    }

    func testUpdateCounterFiveTimeInARowThenNoUsageForTwoDays_isFalse() {
        // i.e data shouldn't be kept longer than 7 days
        let currentDate = Date()
        addUsageDays(from: 0, to: 4, currentDate: currentDate) // 5 days cumulative
        addUsageDays(from: 7, to: 8, currentDate: currentDate) // 2 days no usage + 2 cumulative days

        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)
    }

    func testUpdateCounterMultipleTimesDailyForMultipleDaysExpectDay5_isFalse() {
        // Day 1: Opens the app 3 times
        let currentDate = Date()
        counter.updateCounter(currentDate: currentDate)
        counter.updateCounter(currentDate: currentDate)
        counter.updateCounter(currentDate: currentDate)

        // Day 2: Opens the app 2 times
        updateCounter(numberOfDays: 1, currentDate: currentDate)
        updateCounter(numberOfDays: 1, currentDate: currentDate)

        // Day 3: Opens the app 1 time
        updateCounter(numberOfDays: 2, currentDate: currentDate)

        // Day 4: Opens the app 3 times
        updateCounter(numberOfDays: 3, currentDate: currentDate)
        updateCounter(numberOfDays: 3, currentDate: currentDate)
        updateCounter(numberOfDays: 3, currentDate: currentDate)

        // Day 5: Nothing
        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 4)

        // Day 6: Opens the app 2 times
        updateCounter(numberOfDays: 5, currentDate: currentDate)
        updateCounter(numberOfDays: 5, currentDate: currentDate)
        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)
    }

    func testUpdateCounterMultipleTimesDailyForMultipleDays_isTrue() {
        // Day 1: Opens the app 3 times
        let currentDate = Date()
        counter.updateCounter(currentDate: currentDate)
        counter.updateCounter(currentDate: currentDate)
        counter.updateCounter(currentDate: currentDate)

        // Day 2: Opens the app 2 times
        updateCounter(numberOfDays: 1, currentDate: currentDate)
        updateCounter(numberOfDays: 1, currentDate: currentDate)

        // Day 3: Opens the app 1 time
        updateCounter(numberOfDays: 2, currentDate: currentDate)

        // Day 4: Opens the app 3 times
        updateCounter(numberOfDays: 3, currentDate: currentDate)
        updateCounter(numberOfDays: 3, currentDate: currentDate)
        updateCounter(numberOfDays: 3, currentDate: currentDate)

        // Day 5: Opens the app 1 time
        updateCounter(numberOfDays: 4, currentDate: currentDate)
        XCTAssertTrue(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)

        // Day 6: Opens the app 2 times
        updateCounter(numberOfDays: 5, currentDate: currentDate)
        updateCounter(numberOfDays: 5, currentDate: currentDate)
        XCTAssertTrue(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 6)

        // Day 9: Opens the app 2 times
        updateCounter(numberOfDays: 8, currentDate: currentDate)
        updateCounter(numberOfDays: 8, currentDate: currentDate)
        XCTAssertFalse(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)
    }

    func testHadFiveCumulativeDaysInPastCanBeTrueAgain() {
        // Day 1 to 5: daily usage
        let currentDate = Date()
        addUsageDays(from: 0, to: 4, currentDate: currentDate)
        XCTAssertEqual(counter.daysOfUse?.count, 5)

        // 4 days break then day 9 to 13: daily usage
        addUsageDays(from: 9, to: 13, currentDate: currentDate)
        XCTAssertTrue(counter.hasRequiredCumulativeDaysOfUse)
        XCTAssertEqual(counter.daysOfUse?.count, 5)
    }
}

// MARK: Helpers
private extension CumulativeDaysOfUseCounterTests {
    func addUsageDays(from: Int, to: Int, currentDate: Date) {
        for numberOfDay in from...to {
            updateCounter(numberOfDays: numberOfDay, currentDate: currentDate)
        }
    }

    func updateCounter(numberOfDays: Int, currentDate: Date) {
        let date = calendar.add(numberOfDays: numberOfDays, to: currentDate)!
        counter.updateCounter(currentDate: date)
    }
}
