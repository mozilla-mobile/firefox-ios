/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class RelativeDatesTests: XCTestCase {
    func testRelativeDates() {
        let dateOrig = NSDate()
        var date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        
        XCTAssertTrue(date.toRelativeTimeString() == "Just now")
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-10)
        XCTAssertTrue(date.toRelativeTimeString() == "Just now")
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60)
        XCTAssertTrue(date.toRelativeTimeString() == ("Today at " + NSDateFormatter.localizedStringFromDate(date, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)))
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24)
        XCTAssertTrue(date.toRelativeTimeString() == "Yesterday")
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == "This week")
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7)
        XCTAssertTrue(date.toRelativeTimeString() == "More than a week ago")
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5)
        XCTAssertTrue(date.toRelativeTimeString() == "More than a month ago")
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == NSDateFormatter.localizedStringFromDate(date, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        
        date = NSDate(timeInterval: 0, sinceDate: dateOrig)
        date = date.dateByAddingTimeInterval(-60 * 60 * 24 * 7 * 5 * 12 * 2)
        XCTAssertTrue(date.toRelativeTimeString() == NSDateFormatter.localizedStringFromDate(date, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
    }
}
