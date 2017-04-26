/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import Deferred

import XCTest

open class MockRemoteClientsAndTabs: RemoteClientsAndTabs {
    open let clientsAndTabs: [ClientAndTabs]

    public init() {
        let now = Date.now()
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()
        let u11 = URL(string: "http://test.com/test1")!
        let tab11 = RemoteTab(clientGUID: client1GUID, URL: u11, title: "Test 1", history: [    ], lastUsed: (now - OneMinuteInMilliseconds), icon: nil)

        let u12 = URL(string: "http://test.com/test2")!
        let tab12 = RemoteTab(clientGUID: client1GUID, URL: u12, title: "Test 2", history: [], lastUsed: (now - OneHourInMilliseconds), icon: nil)

        let tab21 = RemoteTab(clientGUID: client2GUID, URL: u11, title: "Test 1", history: [], lastUsed: (now - OneDayInMilliseconds), icon: nil)

        let u22 = URL(string: "http://different.com/test2")!
        let tab22 = RemoteTab(clientGUID: client2GUID, URL: u22, title: "Different Test 2", history: [], lastUsed: now + OneHourInMilliseconds, icon: nil)

        let client1 = RemoteClient(guid: client1GUID, name: "Test client 1", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS")
        let client2 = RemoteClient(guid: client2GUID, name: "Test client 2", modified: (now - OneHourInMilliseconds), type: "desktop", formfactor: "laptop", os: "Darwin")

        let localClient = RemoteClient(guid: nil, name: "Test local client", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS")
        let localUrl1 = URL(string: "http://test.com/testlocal1")!
        let localTab1 = RemoteTab(clientGUID: nil, URL: localUrl1, title: "Local test 1", history: [], lastUsed: (now - OneMinuteInMilliseconds), icon: nil)
        let localUrl2 = URL(string: "http://test.com/testlocal2")!
        let localTab2 = RemoteTab(clientGUID: nil, URL: localUrl2, title: "Local test 2", history: [], lastUsed: (now - OneMinuteInMilliseconds), icon: nil)

        // Tabs are ordered most-recent-first.
        self.clientsAndTabs = [ClientAndTabs(client: client1, tabs: [tab11, tab12]),
                               ClientAndTabs(client: client2, tabs: [tab22, tab21]),
                               ClientAndTabs(client: localClient, tabs: [localTab1, localTab2])]
    }

    open func onRemovedAccount() -> Success {
        return succeed()
    }

    open func wipeClients() -> Success {
        return succeed()
    }

    open func wipeRemoteTabs() -> Deferred<Maybe<()>> {
        return succeed()
    }

    open func wipeTabs() -> Success {
        return succeed()
    }

    open func insertOrUpdateClients(_ clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    open func insertOrUpdateClient(_ client: RemoteClient) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    open func insertOrUpdateTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return insertOrUpdateTabsForClientGUID(nil, tabs: [RemoteTab]())
    }

    open func insertOrUpdateTabsForClientGUID(_ clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(-1)
    }

    open func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe(self.clientsAndTabs)
    }

    open func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return deferMaybe(self.clientsAndTabs.map { $0.client })
    }

    open func getClientGUIDs() -> Deferred<Maybe<Set<GUID>>> {
        return deferMaybe(Set<GUID>(optFilter(self.clientsAndTabs.map { $0.client.guid })))
    }

    open func getTabsForClientWithGUID(_ guid: GUID?) -> Deferred<Maybe<[RemoteTab]>> {
        return deferMaybe(optFilter(self.clientsAndTabs.map { $0.client.guid == guid ? $0.tabs : nil })[0])
    }

    open func deleteCommands() -> Success { return succeed() }
    open func deleteCommands(_ clientGUID: GUID) -> Success { return succeed() }

    open func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> { return deferMaybe([GUID: [SyncCommand]]()) }

    open func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> { return deferMaybe(0) }
    open func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> { return deferMaybe(0) }
}

func removeLocalClient(_ a: ClientAndTabs) -> Bool {
    return a.client.guid != nil
}

func byGUID(_ a: ClientAndTabs, b: ClientAndTabs) -> Bool {
    guard let aGUID = a.client.guid, let bGUID = b.client.guid else {
        return false
    }
    return aGUID < bGUID
}

func byURL(_ a: RemoteTab, b: RemoteTab) -> Bool {
    return a.URL.absoluteString < b.URL.absoluteString
}

class SQLRemoteClientsAndTabsTests: XCTestCase {
    var clientsAndTabs: SQLiteRemoteClientsAndTabs!

    lazy var clients: [ClientAndTabs] = MockRemoteClientsAndTabs().clientsAndTabs

    override func setUp() {
        let files = MockFiles()
        do {
            try files.remove("browser.db")
        } catch _ {
        }
        clientsAndTabs = SQLiteRemoteClientsAndTabs(db: BrowserDB(filename: "browser.db", files: files))
    }

    func testInsertGetClear() {
        // Insert some test data.
        for c in clients {
            let e = self.expectation(description: "Insert.")
            clientsAndTabs.insertOrUpdateClient(c.client).upon {
                XCTAssertTrue($0.isSuccess)
                e.fulfill()
            }
            clientsAndTabs.insertOrUpdateTabsForClientGUID(c.client.guid, tabs: c.tabs).succeeded()
        }

        let f = self.expectation(description: "Get after insert.")
        clientsAndTabs.getClientsAndTabs().upon {
            if let got = $0.successValue {
                let expected = self.clients.sorted(by: byGUID).filter(removeLocalClient)
                let actual = got.sorted(by: byGUID)

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
        ].sorted(by: byGUID)

        func doUpdate(_ guid: String?, tabs: [RemoteTab]) {
            let g0 = self.expectation(description: "Update client: \(guid ?? "nil").")
            clientsAndTabs.insertOrUpdateTabsForClientGUID(guid, tabs: tabs).upon {
                if let rowID = $0.successValue {
                    XCTAssertTrue(rowID > -1)
                } else {
                    XCTFail("Didn't successfully update.")
                }
                g0.fulfill()
            }
        }

        doUpdate(clients[0].client.guid, tabs: client0NewTabs)
        doUpdate(clients[1].client.guid, tabs: client1NewTabs)
        // Also update the local tabs list. It should still not appear in the expected tabs below.
        doUpdate(clients[2].client.guid, tabs: client1NewTabs)

        let h = self.expectation(description: "Get after update.")
        clientsAndTabs.getClientsAndTabs().upon {
            if let clients = $0.successValue {
                XCTAssertEqual(expected, clients.sorted(by: byGUID))
            } else {
                XCTFail("Expected clients!")
            }
            h.fulfill()
        }

        // Now clear everything, and verify we have no clients or tabs whatsoever.
        let i = self.expectation(description: "Clear.")
        clientsAndTabs.clear().upon {
            XCTAssertTrue($0.isSuccess)
            i.fulfill()
        }

        let j = self.expectation(description: "Get after clear.")
        clientsAndTabs.getClientsAndTabs().upon {
            if let clients = $0.successValue {
                XCTAssertEqual(0, clients.count)
            } else {
                XCTFail("Expected clients!")
            }
            j.fulfill()
        }

        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testGetTabsForClient() {
        for c in clients {
            let e = self.expectation(description: "Insert.")
            clientsAndTabs.insertOrUpdateClient(c.client).upon {
                XCTAssertTrue($0.isSuccess)
                e.fulfill()
            }
            clientsAndTabs.insertOrUpdateTabsForClientGUID(c.client.guid, tabs: c.tabs).succeeded()
        }

        let e = self.expectation(description: "Get after insert.")
        let ct = clients[0]
        clientsAndTabs.getTabsForClientWithGUID(ct.client.guid).upon {
            if let got = $0.successValue {
                // This comparison will fail if the order of the tabs changes. We sort the result
                // as part of the DB query, so it's not actively sorted in Swift.
                XCTAssertEqual(ct.tabs.count, got.count)
                XCTAssertEqual(ct.tabs.sorted(by: byURL), got.sorted(by: byURL))
            } else {
                XCTFail("Expected tabs!")
            }
            e.fulfill()
        }

        let f = self.expectation(description: "Get after insert.")
        let localClient = clients[0]
        clientsAndTabs.getTabsForClientWithGUID(localClient.client.guid).upon {
            if let got = $0.successValue {
                // This comparison will fail if the order of the tabs changes. We sort the result
                // as part of the DB query, so it's not actively sorted in Swift.
                XCTAssertEqual(localClient.tabs.count, got.count)
                XCTAssertEqual(localClient.tabs.sorted(by: byURL), got.sorted(by: byURL))
            } else {
                XCTFail("Expected tabs!")
            }
            f.fulfill()
        }

        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
