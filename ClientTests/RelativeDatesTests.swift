/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class RelativeDatesTests: XCTestCase {
    func testRelativeDates() {
        let dateOrig = NSDate()
        var date = NSDate(timeInterval: 0, sinceDate: dateOrig)

        XCTAssertTrue(date.toRelativeTimeString() == "just now")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-10)
        XCTAssertTrue(date.toRelativeTimeString() == "10 seconds ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60)
        XCTAssertTrue(date.toRelativeTimeString() == "a minute ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "2 minutes ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60)
        XCTAssertTrue(date.toRelativeTimeString() == "an hour ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "2 hours ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24)
        XCTAssertTrue(date.toRelativeTimeString() == "a day ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "2 days ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7)
        XCTAssertTrue(date.toRelativeTimeString() == "a week ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "2 weeks ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5)
        XCTAssertTrue(date.toRelativeTimeString() == "a month ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "2 months ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5 * 12)
        XCTAssertTrue(date.toRelativeTimeString() == "a year ago")

        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5 * 12 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "2 years ago")
    }
}