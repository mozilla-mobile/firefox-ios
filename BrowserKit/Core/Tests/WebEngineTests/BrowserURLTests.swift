// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class BrowserURLTests: XCTestCase {
    func testLoadURLGivenNotAURLThenDoesntCreate() {
        let url = URL(string: "blablablablabla")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let subject = BrowserURL(browsingContext: context)

        XCTAssertNil(subject)
    }

    func testLoadURLGivenExampleURLThenCreate() {
        let url = URL(string: "https://www.example.com")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let subject = BrowserURL(browsingContext: context)

        XCTAssertNotNil(subject)
    }
}
