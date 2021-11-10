// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Client

class TabTests: XCTestCase {
    func testWithoutMobilePrefixRemovesMobilePrefixes() {
        let url = URL(string: "https://m.wikipedia.org/wiki/Firefox")!
        let newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "wikipedia.org")
    }

    func testWithoutMobilePrefixRemovesMobile() {
        let url = URL(string: "https://en.mobile.wikipedia.org/wiki/Firefox")!
        let newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "en.wikipedia.org")
    }

    func testWithoutMobilePrefixOnlyRemovesMobileSubdomains() {
        var url = URL(string: "https://plum.com")!
        var newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "plum.com")

        url = URL(string: "https://mobile.co.uk")!
        newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "mobile.co.uk")
    }
}
