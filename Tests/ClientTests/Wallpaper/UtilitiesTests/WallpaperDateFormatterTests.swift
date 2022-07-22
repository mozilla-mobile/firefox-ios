// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

struct WallpaperDateFormatterMock: WallpaperDateFormatter { }

class WallpaperDateFormatterTests: XCTestCase {

    func testDateFormatterReturnsExpectedDate() {
        let sut = WallpaperDateFormatterMock()

        let stringDate = "2001-02-03"
        var dateComponents = DateComponents()
        dateComponents.year = 2001
        dateComponents.month = 2
        dateComponents.day = 3
        let userCalendar = Calendar(identifier: .gregorian)
        guard let expectedDate = userCalendar.date(from: dateComponents) else {
            XCTFail("Error creating expected date.")
            return
        }

        XCTAssertEqual(
            sut.dateFrom(stringDate),
            expectedDate,
            "The returned date was different that the expected date.")
    }

    func testDateFormatterReturnsCurrentDateBecauseOfBadPassedInDate() {
        let sut = WallpaperDateFormatterMock()

        let stringDate = "this is not a date"
        let expectedDate = Calendar.current.startOfDay(for: Date())

        XCTAssertEqual(
            sut.dateFrom(stringDate),
            expectedDate,
            "The returned date was different that the expected date.")
    }
}
