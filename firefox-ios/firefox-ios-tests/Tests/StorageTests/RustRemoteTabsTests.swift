// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Storage

class MockRustRemoteTabs: RustRemoteTabs {
    override public func getAll() -> Deferred<Maybe<[ClientRemoteTabs]>> {
        let url = "https://example.com"
        let title = "example"
        let clientGUID = "AAAAA"
        let tab = RemoteTab(clientGUID: clientGUID,
                            URL: URL(string: url)!,
                            title: title,
                            history: [URL(string: url)!],
                            lastUsed: Date.now(),
                            icon: nil)
        let clientRemoteTab = ClientRemoteTabs(clientId: clientGUID,
                                               clientName: "testClient",
                                               deviceType: .mobile,
                                               lastModified: Int64(Date.now()),
                                               remoteTabs: [tab.toRemoteTabRecord()])

        let url2 = "https://example2.com"
        let title2 = "example2"
        let clientGUID2 = "BBBBB"
        let tab2 = RemoteTab(clientGUID: clientGUID2,
                             URL: URL(string: url2)!,
                             title: title2,
                             history: [URL(string: url2)!],
                             lastUsed: Date.now(),
                             icon: nil)

        let clientRemoteTab2 = ClientRemoteTabs(clientId: clientGUID2,
                                                clientName: "testClient2",
                                                deviceType: .mobile,
                                                lastModified: Int64(Date.now()),
                                                remoteTabs: [tab2.toRemoteTabRecord()])
        return deferMaybe([clientRemoteTab, clientRemoteTab2])
    }
}

class RustRemoteTabsTests: XCTestCase {
    var files: FileAccessor!
    var tabs: RustRemoteTabs!
    var mockTabs: MockRustRemoteTabs!

    override func setUp() {
        super.setUp()
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testTabs.db").path
            try? files.remove("testTabs.db")

            let mockDatabasePath = URL(fileURLWithPath: rootDirectory,
                                       isDirectory: true)
                                        .appendingPathComponent("mockTestTabs.db")
                                        .path
            try? files.remove("mockTestTabs.db")

            tabs = RustRemoteTabs(databasePath: databasePath)
            mockTabs = MockRustRemoteTabs(databasePath: mockDatabasePath)
            _ = tabs.reopenIfClosed()
            _ = mockTabs.reopenIfClosed()
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }

    func testSetLocalTabs() {
        let url = "https://example.com"
        let title = "example"
        let tab = RemoteTab(clientGUID: nil, URL: URL(string: url)!, title: title, history: [URL(string: url)!], lastUsed: Date.now(), icon: nil)

        let count = tabs.setLocalTabs(localTabs: [tab])
            // We are just checking that the `setLocalTabs` call did not return an
            // error as the RustRemoteTabs `getAll` function doesn't not return local tabs.
        XCTAssertTrue(count.value.isSuccess)
        XCTAssertEqual(count.value.successValue, 1)
    }

    func testGetAll() {
        let clientRemoteTabs = tabs.getAll()

        // We are only testing that the `getAll` call did not return an error as
        // this function will only return values after syncing remote records.
        XCTAssertTrue(clientRemoteTabs.value.isSuccess)
        XCTAssertEqual(clientRemoteTabs.value.successValue!.count, 0)
    }

    func testGetClient() {
        let result = mockTabs.getClient(fxaDeviceId: "BBBBB")
        XCTAssertTrue(result.value.isSuccess)
        let clientGUID = result.value.successValue??.guid
        XCTAssertEqual("BBBBB", clientGUID)
    }

    func testGetClientGUIDs() {
        mockTabs.getClientGUIDs { (result, error) in
            XCTAssertNotNil(result)
            XCTAssertEqual(result!.count, 2)
            XCTAssertTrue(result!.contains("AAAAA"))
            XCTAssertTrue(result!.contains("BBBBB"))
        }
    }

    func testGetRemoteClients() {
        let deviceToExclude = "CCCCC"
        let remoteDeviceIds = ["AAAAA", "BBBBB", deviceToExclude]
        let result = mockTabs.getRemoteClients(remoteDeviceIds: remoteDeviceIds)
        XCTAssertTrue(result.value.isSuccess)
        let remoteClients = result.value.successValue!
        XCTAssertEqual(remoteClients.count, 2)
        XCTAssertTrue(remoteDeviceIds.contains(remoteClients[0].client.fxaDeviceId!))
        XCTAssertTrue(remoteDeviceIds.contains(remoteClients[1].client.fxaDeviceId!))

        let filteredResult = remoteClients.filter {
            $0.client.fxaDeviceId == deviceToExclude
        }
        XCTAssertTrue(filteredResult.isEmpty)
    }
}
