// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

extension TopSitesHelperTests {

    // Ecosia: Add check of top sites
    func testGetTopSites_returnsEcosiaSites_withError_completesWithZeroSites() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let subject = createSubject(mockPinnedSites: false)

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }

            XCTAssertTrue((sites.contains(where: { $0.url.asURL?.absoluteString == "https://blog.ecosia.org/ecosia-financial-reports-tree-planting-receipts/" })))
            XCTAssertTrue((sites.contains(where: { $0.url.asURL?.absoluteString == "https://www.ecosia.org/privacy" })))
            XCTAssertTrue((sites.contains(where: { $0.url.asURL?.absoluteString == "https://blog.ecosia.org/tag/where-does-ecosia-plant-trees/" })))

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
