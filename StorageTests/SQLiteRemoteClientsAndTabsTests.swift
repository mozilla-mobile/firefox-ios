/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class SQLRemoteClientsAndTabsTests: XCTestCase {
    var clientsAndTabs: SQLiteRemoteClientsAndTabs!

    lazy var clients: [RemoteClient] = MockRemoteClientsAndTabs().clients

    override func setUp() {
        let files = MockFiles()
        files.remove("browser.db")
        clientsAndTabs = SQLiteRemoteClientsAndTabs(files: files)
    }

    func testInsertGetClear() {
        // Insert some test data.
        for client in clients {
            let e = self.expectationWithDescription("Insert.")
            clientsAndTabs.insertOrUpdateClient(client) { success in
                XCTAssertEqual(success, true)
                e.fulfill()
            }
        }

        let f = self.expectationWithDescription("Get after insert.")
        clientsAndTabs.getClientsAndTabs { (clients: [RemoteClient]?) in
            if let clients = clients {
                XCTAssertEqual(self.clients, clients)
            } else {
                XCTFail("Expected clients!")
            }
            f.fulfill()
        }

        // Update the test data with a client with new tabs, and one with no tabs.
        let clientsWithNewTabs = [
            clients[0].withTabs(clients[1].tabs.map { $0.withClientGUID(self.clients[0].GUID) }),
            clients[1].withTabs([])
        ]

        for client in clientsWithNewTabs {
            let g = self.expectationWithDescription("Update.")
            clientsAndTabs.insertOrUpdateClient(client) { success in
                XCTAssertEqual(success, true)
                g.fulfill()
            }
        }

        let h = self.expectationWithDescription("Get after update.")
        clientsAndTabs.getClientsAndTabs { (clients: [RemoteClient]?) in
            if let clients = clients {
                XCTAssertEqual(clientsWithNewTabs, clients)
            } else {
                XCTFail("Expected clients!")
            }
            h.fulfill()
        }

        // Now clear everything, and verify we have no clients or tabs whatsoever.
        let i = self.expectationWithDescription("Clear.")
        clientsAndTabs.clear { success in
            XCTAssertEqual(success, true)
            i.fulfill()
        }

        let j = self.expectationWithDescription("Get after clear.")
        clientsAndTabs.getClientsAndTabs { (clients: [RemoteClient]?) in
            if let clients = clients {
                XCTAssertEqual(0, clients.count)
            } else {
                XCTFail("Expected clients!")
            }
            j.fulfill()
        }

        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
