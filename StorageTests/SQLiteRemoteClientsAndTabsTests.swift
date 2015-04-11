/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

func byGUID(a: ClientAndTabs, b: ClientAndTabs) -> Bool {
    return a.client.guid < b.client.guid
}

class SQLRemoteClientsAndTabsTests: XCTestCase {
    var clientsAndTabs: SQLiteRemoteClientsAndTabs!

    lazy var clients: [ClientAndTabs] = MockRemoteClientsAndTabs().clientsAndTabs

    override func setUp() {
        let files = MockFiles()
        files.remove("browser.db")
        clientsAndTabs = SQLiteRemoteClientsAndTabs(files: files)
    }


    func testInsertGetClear() {
        // Insert some test data.
        for c in clients {
            let e = self.expectationWithDescription("Insert.")
            clientsAndTabs.insertOrUpdateClient(c.client).upon {
                XCTAssertTrue($0.isSuccess)
                e.fulfill()
            }
            clientsAndTabs.insertOrUpdateTabsForClient(c.client.guid, tabs: c.tabs)
        }

        let f = self.expectationWithDescription("Get after insert.")
        clientsAndTabs.getClientsAndTabs().upon {
            if let got = $0.successValue {
                let expected = self.clients.sorted(byGUID)
                let actual = got.sorted(byGUID)

                // This comparison will fail if the order of the tabs changes. We sort the result
                // as part of the DB query, so it's not actively sorted in Swift.
                XCTAssertEqual(expected, actual)
            } else {
                XCTFail("Expected clients!")
            }
            f.fulfill()
        }

        // Update the test data with a client with new tabs, and one with no tabs.
        let client0NewTabs = clients[1].tabs.map { $0.withClientGUID(self.clients[0].client.guid) }
        let client1NewTabs: [RemoteTab] = []
        let expected = [
            ClientAndTabs(client: clients[0].client, tabs: client0NewTabs),
            ClientAndTabs(client: clients[1].client, tabs: client1NewTabs),
        ].sorted(byGUID)

        func doUpdate(guid: String, tabs: [RemoteTab]) {
            let g0 = self.expectationWithDescription("Update client \(guid).")
            clientsAndTabs.insertOrUpdateTabsForClient(guid, tabs: tabs).upon {
                if let rowID = $0.successValue {
                    XCTAssertTrue(rowID > -1)
                } else {
                    XCTFail("Didn't successfully update.")
                }
                g0.fulfill()
            }
        }

        doUpdate(clients[0].client.guid, client0NewTabs)
        doUpdate(clients[1].client.guid, client1NewTabs)

        let h = self.expectationWithDescription("Get after update.")
        clientsAndTabs.getClientsAndTabs().upon {
            if let clients = $0.successValue {
                XCTAssertEqual(expected, clients.sorted(byGUID))
            } else {
                XCTFail("Expected clients!")
            }
            h.fulfill()
        }

        // Now clear everything, and verify we have no clients or tabs whatsoever.
        let i = self.expectationWithDescription("Clear.")
        clientsAndTabs.clear().upon {
            XCTAssertTrue($0.isSuccess)
            i.fulfill()
        }

        let j = self.expectationWithDescription("Get after clear.")
        clientsAndTabs.getClientsAndTabs().upon {
            if let clients = $0.successValue {
                XCTAssertEqual(0, clients.count)
            } else {
                XCTFail("Expected clients!")
            }
            j.fulfill()
        }

        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
