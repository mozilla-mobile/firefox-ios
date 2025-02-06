// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class ProductionURLProviderTests: XCTestCase {

    var urlProvider: URLProvider = .production

    func testProduction() {
        XCTAssertEqual("https://www.ecosia.org", urlProvider.root.absoluteString)
    }

    func testProductionURLsAreValid() {
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
