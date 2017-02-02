/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class RelativeDatesTests: XCTestCase {
    func testRelativeDates() {
        let dateOrig = Date()
        var date = Date(timeInterval: 0, since: dateOrig)
        
        XCTAssertTrue(date.toRelativeTimeString() == "just now")
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-10)
        XCTAssertTrue(date.toRelativeTimeString() == "just now")
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60)
        XCTAssertTrue(date.toRelativeTimeString() == ("today at " + DateFormatter.localizedStringFromDate(date, dateStyle: DateFormatter.Style.NoStyle, timeStyle: DateFormatter.Style.ShortStyle)))
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60 * 60 * 24)
        XCTAssertTrue(date.toRelativeTimeString() == "yesterday")
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60 * 60 * 24 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "this week")
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60 * 60 * 24 * 7)
        XCTAssertTrue(date.toRelativeTimeString() == "more than a week ago")
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60 * 60 * 24 * 7 * 5)
        XCTAssertTrue(date.toRelativeTimeString() == "more than a month ago")
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60 * 60 * 24 * 7 * 5 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == DateFormatter.localizedStringFromDate(date, dateStyle: DateFormatter.Style.ShortStyle, timeStyle: DateFormatter.Style.ShortStyle))
        
        date = Date(timeInterval: 0, since: dateOrig)
        date = date.addingTimeInterval(-60 * 60 * 24 * 7 * 5 * 12 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == DateFormatter.localizedStringFromDate(date, dateStyle: DateFormatter.Style.ShortStyle, timeStyle: DateFormatter.Style.ShortStyle))
    }
}
