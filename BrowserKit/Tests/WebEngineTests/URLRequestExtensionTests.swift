// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class URLRequestExtensionTests: XCTestCase {
    func testIsPrivilegedWhenNormalURLRequestThenNotPrivileged() {
        let url = URLRequest(url: URL(string: "https://example.com")!)
        XCTAssertFalse(url.isPrivileged)
    }

    func testIsPrivilegedWhenLocalHostThenPrivileged() {
        let url = URLRequest(url: URL(string: "http://localhost:6571/reader-mode-page?url=https:example.com")!)
        XCTAssertTrue(url.isPrivileged)
    }

    func testIsPrivilegedWhenUseInternalSchemeThenPrivileged() {
        let url = URLRequest(url: URL(string: "internal://local/about/home")!)
        XCTAssertTrue(url.isPrivileged)
    }

    func testIsPrivilegedWhenTestFixtureThenNotPrivileged() {
        let url = URLRequest(url: URL(string: "http://localhost:6571/test-fixture/find-in-page.html")!)
        XCTAssertFalse(url.isPrivileged)
    }
}
