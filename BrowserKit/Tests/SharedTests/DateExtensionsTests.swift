// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

class DateExtensionsTests: XCTestCase {
    struct KnownDate {
        var millisecond: Int64
        var date: Date
    }

    func testDateToMillisecondsSince1970() {
        guard let dates = createMillisecondAndDateDictionary() else {
            XCTFail("Error creating dates array")
            return
        }

        dates.forEach { datePair in
            XCTAssertEqual(datePair.date.toMillisecondsSince1970(), datePair.millisecond)
        }
    }

    private func createMillisecondAndDateDictionary() -> [KnownDate]? {
        guard let beginUnixTime = createDateFrom(year: 1970, month: 1, day: 1, hour: 0, minute: 0, second: 0),
              let millenium = createDateFrom(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0),
              let iphoneLaunch = createDateFrom(year: 2007, month: 1, day: 9, hour: 13, minute: 30, second: 0)
        else { return nil }

        return [
            KnownDate(millisecond: 0, date: beginUnixTime),
            KnownDate(millisecond: 946684800000, date: millenium),
            KnownDate(millisecond: 1168349400000, date: iphoneLaunch)
        ]
    }

    private func createDateFrom(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second

        return Calendar(identifier: .gregorian).date(from: dateComponents)
    }

    func test_hasTimePassedBy() {
        let tenHoursInMilliseconds: Timestamp = 3_600_000 * 10

        let lastTimestamp: Timestamp = Date.now() - tenHoursInMilliseconds  // Assuming 10 hours difference.

        XCTAssertTrue(Date.hasTimePassedBy(hours: 10, lastTimestamp: lastTimestamp))

        XCTAssertTrue(Date.hasTimePassedBy(hours: 5, lastTimestamp: lastTimestamp))

        XCTAssertFalse(Date.hasTimePassedBy(hours: 30, lastTimestamp: lastTimestamp))
    }
}
