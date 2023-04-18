// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

final class BundleDomainBuilderTests: XCTestCase {
    func testMobileBundleSite() {
        let subject = BundleDomainBuilder()
        let result = subject.buildDomains(for: URL(string: "https://m.example.com")!)
        XCTAssertEqual(result, ["example", "m.example.com", "example.com"])
    }

    func testPathSite() {
        let subject = BundleDomainBuilder()
        let result = subject.buildDomains(for: URL(string: "https://example.com/to/something")!)
        XCTAssertEqual(result, ["example", "example.com/to/something", "example.com"])
    }
}
