/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class RelativeDatesTests: XCTestCase {
    func testRelativeDates() {
        let dateOrig = Date()
        var date = Date(timeInterval: 0, since: dateOrig)
        
        XCTAssertEqual(date.toRelativeTimeString(), "just now")
        
        date = Date(timeInterval: -10, since: dateOrig)
        XCTAssertEqual(date.toRelativeTimeString(), "just now")

        date = Date(timeInterval: -60, since: dateOrig)
        XCTAssertEqual(date.toRelativeTimeString(), ("today at " + DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.short)))

        let calendar = Calendar.autoupdatingCurrent
        date = calendar.date(byAdding: .day, value: -1, to: dateOrig)!
        XCTAssertEqual(date.toRelativeTimeString(), "yesterday")

        date = calendar.date(byAdding: .day, value: -2, to: dateOrig)!
        XCTAssertEqual(date.toRelativeTimeString(), "this week")

        date = calendar.date(byAdding: .day, value: -7, to: dateOrig)!
        XCTAssertEqual(date.toRelativeTimeString(), "more than a week ago")
        
        date = calendar.date(byAdding: .day, value: -7 * 5, to: dateOrig)!
        XCTAssertEqual(date.toRelativeTimeString(), "more than a month ago")
        
        date = Date(timeInterval: -60 * 60 * 24 * 7 * 5 * 2, since: dateOrig)
        XCTAssertEqual(date.toRelativeTimeString(), DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short))
        
        date = Date(timeInterval: -60 * 60 * 24 * 7 * 5 * 12 * 2, since: dateOrig)
        XCTAssertEqual(date.toRelativeTimeString(), DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short))
    }
}
