/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class ReadingListFetchSpecTestCase: XCTestCase {

    let serviceURLString = "https://readinglist.dev.mozaws.net/v0/"

    private func compareSpec(spec: ReadingListFetchSpec, expectedURL: String) {
        XCTAssertNotNil(spec)

        let serviceURL = NSURL(string: serviceURLString)
        XCTAssertNotNil(serviceURL)

        let url = spec.getURL(serviceURL: serviceURL!)
        XCTAssertNotNil(url)

        let absoluteString = url?.absoluteString
        XCTAssertNotNil(absoluteString)
        XCTAssertEqual(absoluteString!, expectedURL)
    }

    func testFetchSpecBuilder() {
        compareSpec(ReadingListFetchSpec.Builder().setStatus("0", not: false).build(),
            expectedURL: "\(serviceURLString)?status=0")
        compareSpec(ReadingListFetchSpec.Builder().setStatus("0", not: false).setUnread(true).build(),
            expectedURL: "\(serviceURLString)?status=0&unread=true")
        compareSpec(ReadingListFetchSpec.Builder().setStatus("0", not: false).setUnread(true).setMinAttribute("date", value: "1234567890").build(),
            expectedURL: "\(serviceURLString)?status=0&unread=true&min_date=1234567890")
        compareSpec(ReadingListFetchSpec.Builder().setStatus("0", not: false).setUnread(true).setMaxAttribute("cheese", value: "31337").build(),
            expectedURL: "\(serviceURLString)?status=0&unread=true&max_cheese=31337")
    }

}
