/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client

class MigrationTests: TabManagerTests {

    func testEcosiaImportTabs() {
        let urls = [URL(string: "https://ecosia.org")!,
                    URL(string: "https://guacamole.com")!]

        let expectation = XCTestExpectation()

        EcosiaTabs.migrate(urls, to: manager) { result in
            XCTAssertEqual(self.manager.normalTabs.count, 2, "There should be 2 normal tabs")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

}
