/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client
@testable import Core

final class EcosiaTabMigrationTests: TabManagerStoreTests {
    func testEcosiaImportTabs() {
        try? FileManager.default.removeItem(at: FileManager.pages)
        Core.User.shared.migrated = false

        let manager = createManager()

        let urls = [URL(string: "https://ecosia.org")!,
                    URL(string: "https://guacamole.com")!]

        let tabs = Core.Tabs()
        urls.forEach { tabs.new($0) }

        let expectation = XCTestExpectation()
        PageStore.queue.async {
            DispatchQueue.main.async {
                XCTAssertEqual(manager.testCountRestoredTabs(), 2)
                // clean up
                try? FileManager.default.removeItem(at: FileManager.pages)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4)
    }
}
