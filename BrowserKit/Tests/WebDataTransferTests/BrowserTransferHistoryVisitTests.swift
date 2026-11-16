// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebDataTransfer

final class BrowserTransferHistoryVisitTests: XCTestCase {
    func testMilliseconds_roundTripPlacesTimestamp() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/page?q=1"))
        let visit = BrowserTransferHistoryVisit(url: url, title: "Example", millisecondsSince1970: 1_700_000_000_123)

        XCTAssertEqual(visit.visitDate, Date(timeIntervalSince1970: 1_700_000_000.123))
        XCTAssertEqual(visit.millisecondsSince1970, 1_700_000_000_123)
        XCTAssertEqual(visit.url, url)
        XCTAssertEqual(visit.title, "Example")
    }

    func testMilliseconds_fromDateUseMillisecondUnits() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let visit = BrowserTransferHistoryVisit(
            url: url,
            title: nil,
            visitDate: Date(timeIntervalSince1970: 1_600_000_000.5)
        )

        XCTAssertEqual(visit.millisecondsSince1970, 1_600_000_000_500)
        XCTAssertNil(visit.title)
    }

    func testMilliseconds_outOfRangeDates_clampInsteadOfTrapping() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))

        XCTAssertEqual(BrowserTransferHistoryVisit(url: url, title: nil, visitDate: .distantFuture).millisecondsSince1970,
                       Int64((Date.distantFuture.timeIntervalSince1970 * 1000).rounded()))
        XCTAssertEqual(BrowserTransferHistoryVisit(url: url, title: nil, visitDate: Date(timeIntervalSince1970: 1e300))
            .millisecondsSince1970, Int64.max)
        XCTAssertEqual(BrowserTransferHistoryVisit(url: url, title: nil, visitDate: Date(timeIntervalSince1970: .nan))
            .millisecondsSince1970, 0)
    }

    func testMilliseconds_dateBefore1970_clampsToZero() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let visit = BrowserTransferHistoryVisit(url: url, title: nil, visitDate: Date(timeIntervalSince1970: -10))

        XCTAssertEqual(visit.millisecondsSince1970, 0)
    }
}
