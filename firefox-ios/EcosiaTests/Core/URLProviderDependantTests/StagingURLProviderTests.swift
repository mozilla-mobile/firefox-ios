// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class StagingURLProviderTests: XCTestCase {

    var urlProvider: URLProvider = .staging

    func testStaging() {
        XCTAssertEqual("https://www.ecosia-staging.xyz", urlProvider.root.absoluteString)
    }

    func testStagingURLsAreValid() {
        XCTAssertNotNil(urlProvider.root)
        XCTAssertNotNil(urlProvider.statistics)
        XCTAssertNotNil(urlProvider.privacy)
        XCTAssertNotNil(urlProvider.faq)
        XCTAssertNotNil(urlProvider.terms)
        XCTAssertNotNil(urlProvider.aboutCounter)
        XCTAssertNotNil(urlProvider.snowplow)
        XCTAssertNotNil(urlProvider.notifications)
    }
}
