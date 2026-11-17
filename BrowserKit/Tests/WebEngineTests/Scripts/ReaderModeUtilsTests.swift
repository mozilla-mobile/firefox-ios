// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class ReaderModeUtilsTests: XCTestCase {
    func testContentSecurityPolicy_isSingleLine() {
        let csp = ReaderModeUtils.contentSecurityPolicy(origin: "http://localhost:*")

        XCTAssertFalse(csp.contains("\n"))
        XCTAssertFalse(csp.contains("\r"))
    }

    func testContentSecurityPolicy_usesGivenOrigin() {
        let csp = ReaderModeUtils.contentSecurityPolicy(origin: "readermode://app")

        XCTAssertEqual(
            csp,
            "default-src 'none'; img-src *; style-src 'unsafe-inline' readermode://app; font-src readermode://app"
        )
    }
}
